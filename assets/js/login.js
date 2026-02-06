const signupbtn = document.getElementById("signupbtn");
const loginbtn = document.getElementById("loginbtn");

signupbtn.addEventListener("click", signup);
loginbtn.addEventListener("click", login);

async function signup() {
	const username = document.getElementById("signupname").value;
	const email = document.getElementById("signupemail").value;
	const password = document.getElementById("signuppass").value;

	if (!username || !email || !password) {
		alert("Please fill all fields");
		return;
	}

	const response = await fetch("/signup", {
		method: "POST",
		headers: {
			"Content-Type": "application/json",
		},
		body: JSON.stringify({
			username: username,
			email: email,
			password: password,
		}),
	});

	if (response.ok) {
		window.location.href = "/opportunities";
	} else {
		const data = await response.json();
		alert(data.error || "Signup failed");
	}
}

async function login() {
	const email = document.getElementById("loginemail").value;
	const password = document.getElementById("loginpass").value;

	if (!email || !password) {
		document.getElementById("error").innerText = "Please fill all fields";
		return;
	}

	const response = await fetch("/login", {
		method: "POST",
		headers: {
			"Content-Type": "application/json",
		},
		body: JSON.stringify({
			email: email,
			password: password,
		}),
	});

	if (response.ok) {
		window.location.href = "/opportunities";
	} else {
		const data = await response.json();
		document.getElementById("error").innerText = data.error || "Login failed";
	}
}
