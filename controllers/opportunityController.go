package controller

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/gvinton/wiz/auth"
	"github.com/gvinton/wiz/database"
	"github.com/gvinton/wiz/models"
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

var opportunityCollection *mongo.Collection = database.OpenCollection(database.Client, "opportunities")

func GetOpportunity(c *gin.Context) {
	var ctx, cancel = context.WithTimeout(context.Background(), 100*time.Second)

	id := c.Param("id")
	objId, _ := primitive.ObjectIDFromHex(id)

	var opportunity models.Opportunity
	err := opportunityCollection.FindOne(ctx, bson.M{"_id": objId}).Decode(&opportunity)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error ": err.Error()})
	}

	defer cancel()
	c.JSON(http.StatusOK, opportunity)
}

func ClearAll(c *gin.Context) {
	session := auth.ValidateSession(c)
	if !session {
		return
	}

	var ctx, cancel = context.WithTimeout(context.Background(), 100*time.Second)
	userid := c.Param("userid")
	_, err := opportunityCollection.DeleteMany(ctx, bson.M{"userid": userid})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	defer cancel()
	c.JSON(http.StatusOK, gin.H{"success": "All opportunities deleted."})
}

func GetOpportunities(c *gin.Context) {
	session := auth.ValidateSession(c)
	if !session {
		return
	}
	var ctx, cancel = context.WithTimeout(context.Background(), 100*time.Second)
	userid := c.Param("userid")
	findResult, err := opportunityCollection.Find(ctx, bson.M{"userid": userid})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"FindError": err.Error()})
		return
	}

	var opportunities []models.Opportunity
	for findResult.Next(ctx) {
		var opportunity models.Opportunity
		err := findResult.Decode(&opportunity)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"Decode Error": err.Error()})
			return
		}
		opportunities = append(opportunities, opportunity)
	}
	defer cancel()

	c.JSON(http.StatusOK, opportunities)
}

func DeleteOpportunity(c *gin.Context) {
	session := auth.ValidateSession(c)
	if !session {
		return
	}
	var ctx, cancel = context.WithTimeout(context.Background(), 100*time.Second)

	id := c.Param("id")
	userid := c.Param("userid")
	objId, _ := primitive.ObjectIDFromHex(id)
	deleteResult, err := opportunityCollection.DeleteOne(ctx, bson.M{"_id": objId, "userid": userid})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if deleteResult.DeletedCount == 0 {
		msg := fmt.Sprintf("No opportunity with id : %v was found, no deletion occurred.", id)
		c.JSON(http.StatusBadRequest, gin.H{"error": msg})
		return
	}
	defer cancel()

	msg := fmt.Sprintf("opportunity with id : %v was deleted successfully.", id)
	c.JSON(http.StatusOK, gin.H{"success": msg})
}

func UpdateOpportunity(c *gin.Context) {
	session := auth.ValidateSession(c)
	if !session {
		return
	}
	var ctx, cancel = context.WithTimeout(context.Background(), 100*time.Second)
	var newOpportunity models.Opportunity
	if err := c.BindJSON(&newOpportunity); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	_, err := opportunityCollection.UpdateOne(ctx, bson.M{"_id": newOpportunity.ID, "userid": newOpportunity.UserID}, bson.M{"$set": newOpportunity})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		fmt.Println(err.Error())
		return
	}

	defer cancel()

	c.JSON(http.StatusOK, newOpportunity)
}

func AddOpportunity(c *gin.Context) {
	session := auth.ValidateSession(c)
	if !session {
		return
	}
	var ctx, cancel = context.WithTimeout(context.Background(), 100*time.Second)

	var opportunity models.Opportunity
	if err := c.BindJSON(&opportunity); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	opportunity.ID = primitive.NewObjectID()
	opportunity.UserID = c.Param("userid")

	_, err := opportunityCollection.InsertOne(ctx, opportunity)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer cancel()
	c.JSON(http.StatusOK, gin.H{"insertedId": opportunity.ID})
}
