var jsonFileToUrl = 'actions-data-url.txt';
var jsonUrl = 'actions-data.json';

function loadFile(url, isJson, callback) {
    var xobj = new XMLHttpRequest();
    if (isJson) {
        xobj.overrideMimeType("application/json");
    }

    xobj.open('GET', url, true);
    xobj.onreadystatechange = function () {
        if (xobj.readyState == 4 && xobj.status == "200") {
            // Required use of an anonymous callback as .open will NOT return a value but simply returns undefined in asynchronous mode
            callback(xobj.responseText);
        }
    };
    xobj.send(null);
}

function addActionPanel(mainElement, action) {
    var panel = document.createElement('div');
    panel.className = "panel";
    panel.id = action.repoName
    panel.innerHTML = '<div class="line"><span class="name">Repository:</span><span class="value"><a href="https://github.com/test-gha-market/'+action.repoName+'">'+action.repoName+'</a></span></div>';
    panel.innerHTML += '<div class="line"><span class="name">Action:</span><span class="value">'+action.name+'</span></div>';
    panel.innerHTML += '<div class="line"><span class="name">Author:</span><span class="value">'+(action.author || "Not set") +'</span></div>';
    panel.innerHTML += '<div class="line"><span class="name">Description:</span><div class="value description">'+action.description+'</div></div>';

    mainElement.appendChild(panel);
}

function setLastUpdated(lastUpdated) {
    var splitted = lastUpdated.split("_");
    var date = splitted[0];
    var time = splitted[1];
    var splittedTime = time.split(/(?=(?:..)*$)/);

    var year = parseInt(date.substring(0, 4));
    var month = parseInt(date.substring(4, 6));
    var day = parseInt(date.substring(6, 8));

    var date = new Date(year, month, day, splittedTime[0], splittedTime[1], 0, 0);

    document.getElementById('lastUpdated').innerHTML = date.toLocaleString();
}

function init() {
    loadFile(jsonFileToUrl, false, function(response) {
        console.log('found file with content' + response);
        var jsonFileToUrl = response;

        loadFile(jsonFileToUrl, true, function(response) {
            var json = JSON.parse(response);
            var mainElement = document.getElementById('main');
            var actionCountElement = document.getElementById('actionCount');
            var actionsOwnerElement = document.getElementById('actionOwners');

            actionCountElement.innerHTML = json.actions.length;
            actionsOwnerElement.innerHTML = json.organization ? json.organization : json.user;
            setLastUpdated(json.lastUpdated);

            for(var index in json.actions) {
                var action = json.actions[index];

                addActionPanel(mainElement, action);
            }
        }
        )}
    )
}
