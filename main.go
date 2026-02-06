package main

import (
	"net/http"

	controller "github.com/gvinton/wiz/controllers"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func index(c *gin.Context) {
	c.HTML(http.StatusOK, "login.html", nil)
}

func main() {
	godotenv.Overload()

	router := gin.Default()
	router.LoadHTMLGlob("assets/*.html")
	router.Static("/assets", "./assets")

	router.GET("/", index)
	router.GET("/opportunities/:userid", controller.GetOpportunities)
	router.GET("/opportunity/:id", controller.GetOpportunity)
	router.POST("/opportunity/:userid", controller.AddOpportunity)
	router.DELETE("/opportunity/:userid/:id", controller.DeleteOpportunity)
	router.DELETE("/opportunities/:userid", controller.ClearAll)
	router.PUT("/opportunity", controller.UpdateOpportunity)

	router.POST("/signup", controller.SignUp)
	router.POST("/login", controller.Login)
	router.GET("/opportunities", controller.Opportunities)

	router.Run(":8080")
}
