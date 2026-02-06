let userId = getCookie("userID");
let username = getCookie("username");

document.getElementById("username").innerText = username || "User";

window.onload = function () {
	loadOpportunities();
};

function getCookie(name) {
	const value = `; ${document.cookie}`;
	const parts = value.split(`; ${name}=`);
	if (parts.length === 2) return parts.pop().split(";").shift();
}

async function loadOpportunities() {
	const response = await fetch(`/opportunities/${userId}`);
	if (response.ok) {
		const opportunities = await response.json();
		displayOpportunities(opportunities);
	} else {
		console.error("Failed to load opportunities");
	}
}

function displayOpportunities(opportunities) {
	const list = document.getElementById("opportunitiesList");
	
	if (!opportunities || opportunities.length === 0) {
		list.innerHTML = '<div class="empty-state">No opportunities yet. Add one above!</div>';
		return;
	}

	list.innerHTML = "";
	opportunities.forEach((opp) => {
		const oppDiv = document.createElement("div");
		oppDiv.className = "opportunity-item";
		oppDiv.innerHTML = `
			<div class="opportunity-content">
				<div class="opportunity-name">${opp.name}</div>
				<div class="opportunity-value">$${parseFloat(opp.value).toLocaleString('en-US', {minimumFractionDigits: 2, maximumFractionDigits: 2})}</div>
			</div>
			<span class="opportunity-status status-${opp.status}">${opp.status}</span>
			<button class="delete-btn" onclick="deleteOpportunity('${opp._id}')">Delete</button>
		`;
		list.appendChild(oppDiv);
	});
}

async function addOpportunity() {
	const name = document.getElementById("oppName").value;
	const value = document.getElementById("oppValue").value;

	if (!name || !value) {
		alert("Please fill in both opportunity name and value");
		return;
	}

	const response = await fetch(`/opportunity/${userId}`, {
		method: "POST",
		headers: {
			"Content-Type": "application/json",
		},
		body: JSON.stringify({
			name: name,
			value: parseFloat(value),
			status: "open",
		}),
	});

	if (response.ok) {
		document.getElementById("oppName").value = "";
		document.getElementById("oppValue").value = "";
		loadOpportunities();
	} else {
		alert("Failed to add opportunity");
	}
}

async function deleteOpportunity(id) {
	const response = await fetch(`/opportunity/${userId}/${id}`, {
		method: "DELETE",
	});

	if (response.ok) {
		loadOpportunities();
	} else {
		alert("Failed to delete opportunity");
	}
}

async function clearAll() {
	if (!confirm("Are you sure you want to delete all opportunities?")) {
		return;
	}

	const response = await fetch(`/opportunities/${userId}`, {
		method: "DELETE",
	});

	if (response.ok) {
		loadOpportunities();
	} else {
		alert("Failed to clear opportunities");
	}
}

function logout() {
	document.cookie = "token=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
	document.cookie = "userID=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
	document.cookie = "username=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
	window.location.href = "/";
}
