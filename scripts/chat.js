function messageobj(parameter) {
	this.type = "message";
	this.message = parameter;
}

function sendChatMessage() {
	var input = document.getElementById('message-box');
	var message = new messageobj(input.value);
	var myJSONText = JSON.stringify(message);
	// Send message
	ws.send(myJSONText);
	input.value = "";
}

function addChatMessage(player,txt) {
	var message = document.createElement('div');
	message.appendChild(document.createTextNode(player + " : "+ txt));
	var display = document.getElementById('chatdisplay');
	display.appendChild(message);
	display.scrollTop = display.scrollHeight;
}