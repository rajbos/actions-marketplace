var jsonFileToUrl = 'actions-data-url.txt';
var jsonUrl = 'actions-data.json';
var allActions = [];

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
    panel.id = action.repo;
    panel.setAttribute('data-name', action.name.toLowerCase());
    panel.setAttribute('data-repo', action.repo.toLowerCase());
    panel.setAttribute('data-author', (action.author || '').toLowerCase());
    panel.setAttribute('data-description', action.description.toLowerCase());
    
    // Determine visibility status
    var isPrivate = action.private === true;
    var visibilityClass = isPrivate ? 'visibility-badge-private' : 'visibility-badge-public';
    var visibilityText = isPrivate ? 'Private' : 'Public';
    var visibilityIcon = isPrivate ? '🔒' : '🌐';
    
    panel.innerHTML = `<div class="line"><span class="name">Repository:</span><span class="value"><a href="https://github.com/${action.owner}/${action.repo}">${action.repo}</a><span class="visibility-badge ${visibilityClass}">${visibilityIcon} ${visibilityText}</span></span></div>`;
    panel.innerHTML += '<div class="line"><span class="name">Action:</span><span class="value">'+action.name+'</span></div>';
    panel.innerHTML += '<div class="line"><span class="name">Author:</span><span class="value">'+(action.author || "Not set") +'</span></div>';
    panel.innerHTML += '<div class="line"><span class="name">Description:</span><div class="value description">'+action.description+'</div></div>';

    mainElement.appendChild(panel);
}

function filterActions(searchTerm) {
    var panels = document.querySelectorAll('.panel');
    var searchLower = searchTerm.toLowerCase().trim();
    var visibleCount = 0;
    
    panels.forEach(function(panel) {
        var name = panel.getAttribute('data-name') || '';
        var repo = panel.getAttribute('data-repo') || '';
        var author = panel.getAttribute('data-author') || '';
        var description = panel.getAttribute('data-description') || '';
        
        var matches = searchLower === '' || 
                     name.indexOf(searchLower) !== -1 || 
                     repo.indexOf(searchLower) !== -1 || 
                     author.indexOf(searchLower) !== -1 || 
                     description.indexOf(searchLower) !== -1;
        
        if (matches) {
            panel.style.display = 'block';
            visibleCount++;
        } else {
            panel.style.display = 'none';
        }
    });
    
    var actionCountElement = document.getElementById('actionCount');
    actionCountElement.innerHTML = visibleCount;
}

function setLastUpdated(lastUpdated) {
    var splitted = lastUpdated.split("_");
    var date = splitted[0];
    var time = splitted[1];

    var splittedDate = date.split(/(?=(?:..)*$)/);
    var splittedTime = time.split(/(?=(?:..)*$)/);

    var date = new Date(splittedDate[0]+splittedDate[1],splittedDate[2]-1,splittedDate[3], splittedTime[0], splittedTime[1]);

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

            allActions = json.actions;
            actionCountElement.innerHTML = json.actions.length;
            setLastUpdated(json.lastUpdated);

            for(var index in json.actions) {
                var action = json.actions[index];
                addActionPanel(mainElement, action);
            }
            
            // Setup search functionality
            var searchInput = document.querySelector('.search input');
            searchInput.addEventListener('input', function(e) {
                filterActions(e.target.value);
            });
        }
        )}
    )
}
    
