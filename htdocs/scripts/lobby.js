function creategame(name,bots) {
	this.type = "creategame";
	this.name = name;
	this.bots = bots;
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
	listdiv.setAttribute("id",'gamelist');
	listdiv.innerHTML = "<h2>List of games</h2>";
	$('#lobby').append(listdiv);
	
	var $createform = $('<form></form>');
	$createform.append("<label for='gamename'>Game Name</label><input  type='text' id='gamename' name='name'>");
	$createform.append("<br><label for='bots'>Bots</label><select id='bots' class='multiselect' multiple='multiple' name='bots'><option value='DumbMoney'>Dumb Money</option><option value='FullRetard'>FullRetard</option><option value='HalfRetard'>HalfRetard</option><option value='MoneyWhore'>MoneyWhore</option></select><br>");
	var creategamebutton = document.createElement('button');
	creategamebutton.setAttribute("type","button");
	creategamebutton.setAttribute("id", 'creategamebutton');
	creategamebutton.innerHTML='Create Game';
	$createform.append(creategamebutton);
	
	$('#lobby').append($createform);
	$('#creategamebutton').click(function() {
		var message = new creategame(document.getElementById('gamename').value,getSelected(document.getElementById('bots')));
		ws.send(JSON.stringify(message));
		
	});
	$('#chatname').blur(function() {
		changename(this.innerHTML);
	});
	//$(".multiselect").multiselect({sortable: false, searchable: false});
	$(".multiselect").multiselect();
}

function showlistofgames(com) {
	var $listul = $('<ul></ul>');
	$('#gamelist').append($listul);
	for( i in com.games) {
		var game = document.createElement('li');
		var gamelink = document.createElement('a');
		
		gamelink.innerHTML =  com.games[i].name + ' - ' + com.games[i].state;
		if (com.games[i].state == 'pregame' || com.games[i].state =='postgame') {
			gamelink.setAttribute('onclick','joingame\(\''+ com.games[i].id +'\'\);return false;');
			gamelink.setAttribute('href','#');
		}
		$listul.append(game);
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

function getSelected(opt) {
    var selected = new Array();
    var index = 0;
    for (var intLoop=0; intLoop < opt.length; intLoop++) {
       if (opt[intLoop].selected) {
          index = selected.length;
          selected[index] = new Object;
          selected[index].value = opt[intLoop].value;
          selected[index].index = intLoop;
       }
    }
    return selected;
 }