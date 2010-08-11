
function nameupdate(parameter) {
	this.type = "namechange";
	this.name = parameter;
}
function choiceresponse(parameter,card) {
	this.type = "choiceresponse";
	this.event = parameter;
	if(card) {this.card = card;}
}

function startgame() {
	this.type = "startgame";
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
	drawGameArea();
	if (localStorage.getItem('playername')) {
		$('#chatname').html(localStorage.getItem('playername'));
	}
	// Connect to Web Socket.
	ws = new WebSocket('ws://localhost:3000');
	
	ws.onclose = function (event) {
		addChatMessage("Your browser","The server seems to have up and quit on us!");
	};
	ws.onopen = function (event) {
		if (localStorage.getItem('playername')) {
			changename(localStorage.getItem('playername'));
		}
	}
	// Receive message
	ws.onmessage = function(e) {
		// Write message
		var com = jQuery.parseJSON(e.data);
		console.log("Json recived  type:" + com.type + " -- " + e.data);
		
		if (com.section == 'game') {
			processGameMessage(com);
		}
		
		
		//addChatMessage('Debug',e.data);
	};
	
	
	$('#chatname').blur(function() {
		changename(this.innerHTML);
	});
}

function makehanddraggable (cards) {
	console.log("Make Hand Draggable "  + cards);
	var oldarr = new Array();
	for ( var i in cards ) {
		oldarr.push(cards[i].name);
	}
	oldarr.sort();j=0;
	newarr= new Array();
	for(var i=0;i<oldarr.length;i++){
		newarr[j]=oldarr[i];j++;
		if((i>0)&&(oldarr[i]==oldarr[i-1])){
			newarr.pop();
			j--;
		}
	}
	var cardsdraggable = new Array();
	for ( var i in newarr ) {
		$('#handcards').find(".card-"+newarr[i]).each(function(index,value) {
			//TODO only make the cards in the choice type draggable...
			//For chapple that dosn't matter :D
			
			$('#' + value.id).draggable({ 
		        revert: 'invalid', 
		        scroll: false,
		        helper: function(){ 
					var c = $(this).clone();
					c.width($(this).width());
					c.height($(this).height());
					c.attr('id','tempclonecard');
					
					return c;
				},
		        start : function() {
		        	this.style.display="none";
		        },
		        stop: function() {
		        	this.style.display="";
		        }
		    });
			
			$('#' + value.id).fadeTo('fast', 1);
			cardsdraggable.push($(this).attr('id'));
			
		});
	}
	//Iterate over all the cards in the hand making those not dragable greyed out.
	$('#handcards').find(".card").each(function(index,value) {
		
		if(cardsdraggable.indexOf($(this).attr('id'))==-1) {
			$(this).fadeTo('slow', 0.2);
		}
	});
		
}
function makesupplydraggable ( cards) {
	var oldarr = new Array();
	for ( var i in cards ) {
		oldarr.push(cards[i].name);
	}
	
	oldarr.sort();j=0;
	newarr= new Array();
	for(var i=0;i<oldarr.length;i++){
		newarr[j]=oldarr[i];j++;
		if((i>0)&&(oldarr[i]==oldarr[i-1])){
			newarr.pop();
			j--;
		}
	}
	$('#supplycards').find(".card").each(function(index,value) {
		$('#' + value.id).fadeTo('fast', 0.2);
	});
	for ( var i in newarr ) {
		$('#supplycards').find(".card-"+newarr[i]).each(function(index,value) {
			$('#' + value.id).draggable({helper: clonehelper});
			$('#' + value.id).fadeTo('fast', 1);
				
		});
	}
}


function changename (name) {
	var message = new nameupdate(name);
	localStorage.setItem('playername', name);	
	ws.send(JSON.stringify(message));
}
function clonehelper () {
	var c = $(this).clone();
	c.width($(this).width());
	c.height($(this).height());
	c.attr('id','tempclonecard');
	return c;
}

function preparehandforbuy() {
	$('#handcards').children(".card").each(function(index,value) {
		$('#' + value.id).draggable("disable");
		$('#' + value.id).removeClass("ui-draggable");
		if(hand[$('#' + value.id).attr("cardnum")].type == 'Treasure') {
			$('#' + value.id).fadeTo('slow', 1);
		} else {
			$('#' + value.id).fadeTo('slow', 0.4);
		}
	});
}

function hasClass(ele,cls) {
	return ele.className.match(new RegExp('(\\s|^)'+cls+'(\\s|$)'));
}
 
function addClass(ele,cls) {
	if (!this.hasClass(ele,cls)) ele.className += " "+cls;
}

function removeClass(ele,cls) {
	if (hasClass(ele,cls)) {
    	var reg = new RegExp('(\\s|^)'+cls+'(\\s|$)');
		ele.className=ele.className.replace(reg,' ');
	}
}

function addStartButton() {
	//DO some stuff like add a start game button
	var control = document.getElementById('control');
	var startbutton = document.createElement('div');
	startbutton.setAttribute("id", "startcontainer");
	startbutton.innerHTML="<button type='button' id='startgame'>Start Game!</button>";
	control.appendChild(startbutton);
	$('#startgame').click(function() {
		var message = new startgame();
		ws.send(JSON.stringify(message));
	});
}
window.onload = init;



