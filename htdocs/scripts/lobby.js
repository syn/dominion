function creategame() {
	this.type = "creategame";
}

function processLobbyMessage(com) {
	if (com.type == 'message') {
		addChatMessage(com.from,com.message);
		return;
	}
	if (com.type == 'listofgames') {
		showlistofgames(com);
		return;
	}
	
}

function drawLobby () {
	$('#container').html("<div id='lobby'></div>" +
	"<div id='chat'>" +
	"	<div id='chatdisplay'></div>" +
	"	<section id='chatname' contenteditable='true'></section>" +
	"	<form onsubmit=\"sendChatMessage('lobby'); return false;\" id='messageform'>" +
    "		<input  type='text' id='message-box'>" +
	"	</form>" +
	"</div>"
	);
	var listdiv = document.createElement('div');
	listdiv.innerHTML = "<h2>List of games</h2><div id='gamelist'></div>";
	$('#lobby').append(listdiv);
	
	var creategamebutton = document.createElement('button');
	creategamebutton.setAttribute("type","button");
	creategamebutton.setAttribute("id", 'creategamebutton');
	creategamebutton.innerHTML='Create Game';
	$('#lobby').append(creategamebutton);
	$('#creategamebutton').click(function() {
		var message = new creategame();
		ws.send(JSON.stringify(message));
		
	});
	$('#chatname').blur(function() {
		changename(this.innerHTML);
	});
}

function showlistofgames(com) {
	$('#gamelist').html('<ul></ul>');
	for( i in com.games) {
		var game = document.createElement('li');
		var gamelink = document.createElement('a');
		
		gamelink.innerHTML =  com.games[i].name + ' - ' + com.games[i].state;
		if (com.games[i].state == 'pregame' || com.games[i].state =='postgame') {
			gamelink.setAttribute('onclick','joingame\(\''+ com.games[i].id +'\'\);return false;');
			gamelink.setAttribute('href','#');
		}
		$('#gamelist').append(game);
		$(game).append(gamelink);
	}
}
function joingame(id) {
	var message = new joingameobj(id);
	ws.send(JSON.stringify(message));
}

function joingameobj(param) {
	this.type = "joingame";
	this.gameid =  param;
}
function requestlistofgames () {
	var message = new listofgames();
	ws.send(JSON.stringify(message));
}

function listofgames() {
	this.type = "listofgames";
}
