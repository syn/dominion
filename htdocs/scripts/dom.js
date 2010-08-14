
function nameupdate(parameter) {
	this.type = "namechange";
	this.name = parameter;
}


if (WebSocket.__initialize) {
	// Set URL of your WebSocketMain.swf here:
	WebSocket.__swfLocation = 'web-socket-js/WebSocketMain.swf';
}

// example copied from web-socket-js/sample.html
var ws, input, clock;

var supply;
var hand;
var gold;
var buys;
var discards; //Used by Militia, for when the player has to discard multiple cards
var lastPlayUpdate;
var actioncount=0;
var statusbackup = "";  // used when I have to temporarily replace the status message
var gameover = false;
function init() {
	drawLobby();
	
	if (localStorage.getItem('playername')) {
		$('#chatname').html(localStorage.getItem('playername'));
	}
	// Connect to Web Socket.
	ws = new WebSocket('ws://dominion.lawn.net.nz:3000');
	
	ws.onclose = function (event) {
		addChatMessage("Your browser","The server seems to have up and quit on us!");
	};
	ws.onopen = function (event) {
		if (localStorage.getItem('playername')) {
			changename(localStorage.getItem('playername'));
		}
		requestlistofgames();
	}
	// Receive message
	ws.onmessage = function(e) {
		// Write message
		var com = jQuery.parseJSON(e.data);
		console.log("Json recived  type:" + com.type + " -- " + e.data);
		
		if (com.section == 'game') {
			processGameMessage(com);
		}
		if (com.section == 'lobby') {
			processLobbyMessage(com);
		}
		
		
		//addChatMessage('Debug',e.data);
	};	
	
}

window.onload = init;



