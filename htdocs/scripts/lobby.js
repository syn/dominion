function creategame() {
	this.type = "creategame";
}

function processLobbyMessage() {
	
	
}

function drawLobby () {
	$('#container').html("<div id='lobby'></div>" +
	"<div id='chat'>" +
	"	<div id='chatdisplay'></div>" +
	"	<section id='chatname' contenteditable='true'></section>" +
	"	<form onsubmit='sendChatMessage(); return false;' id='messageform'>" +
    "		<input  type='text' id='message-box'>" +
	"	</form>" +
	"</div>"
	);
	listofgames();
}

function listofgames() {
	
	var listdiv = document.createElement('div');
	listdiv.innerHTML = "<h2>List of games</h2><div id='gamemenu'></div>";
	$('#lobby').append(listdiv);
	
	var creategamebutton = document.createElement('button');
	creategamebutton.setAttribute("type","button");
	creategamebutton.setAttribute("id", 'creategamebutton');
	creategamebutton.innerHTML='Create Game';
	$('#gamemenu').append(creategamebutton);
	$('#creategamebutton').click(function() {
		var message = new creategame();
		ws.send(JSON.stringify(message));
		drawGameArea();
	});
	
	
}
