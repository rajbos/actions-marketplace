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
            callback(xobj.responseText);
        }
    };
    xobj.send(null);  
}

function getRepoFromUrl() {
    var urlParams = new URLSearchParams(window.location.search);
    return urlParams.get('repo');
}

function displayActionDetail(action) {
    var detailElement = document.getElementById('actionDetail');
    
    if (!action) {
        detailElement.innerHTML = '<div class="detail-error">Action not found. <a href="index.html">Return to marketplace</a></div>';
        return;
    }

    // Determine visibility status
    var isPrivate = action.private === true;
    var visibilityClass = isPrivate ? 'visibility-badge-private' : 'visibility-badge-public';
    var visibilityText = isPrivate ? 'Private' : 'Public';
    var visibilityIcon = isPrivate ? '🔒' : '🌐';
    
    var html = '<div class="detail-header">';
    html += '<h2>' + action.name + '</h2>';
    html += '<span class="visibility-badge ' + visibilityClass + '">' + visibilityIcon + ' ' + visibilityText + '</span>';
    html += '</div>';
    
    html += '<div class="detail-section">';
    html += '<h3>Repository</h3>';
    var ownerName = action.owner || '';
    html += '<p><a href="https://github.com/' + ownerName + '/' + action.repo + '" target="_blank">' + ownerName + '/' + action.repo + '</a></p>';
    html += '</div>';
    
    if (action.author) {
        html += '<div class="detail-section">';
        html += '<h3>Author</h3>';
        html += '<p>' + action.author + '</p>';
        html += '</div>';
    }
    
    html += '<div class="detail-section">';
    html += '<h3>Description</h3>';
    html += '<p>' + action.description + '</p>';
    html += '</div>';
    
    if (action.downloadUrl) {
        html += '<div class="detail-section">';
        html += '<h3>Action File</h3>';
        html += '<p><a href="' + action.downloadUrl + '" target="_blank">View action.yml</a></p>';
        html += '</div>';
    }
    
    detailElement.innerHTML = html;
}

function initDetail() {
    var repoName = getRepoFromUrl();
    
    if (!repoName) {
        var detailElement = document.getElementById('actionDetail');
        detailElement.innerHTML = '<div class="detail-error">No action specified. <a href="index.html">Return to marketplace</a></div>';
        return;
    }

    loadFile(jsonFileToUrl, false, function(response) {
        var jsonFileToUrl = response;

        loadFile(jsonFileToUrl, true, function(response) {
            var json = JSON.parse(response);
            var action = null;
            
            // Find the action by repo name
            for(var index in json.actions) {
                if (json.actions[index].repo === repoName) {
                    action = json.actions[index];
                    break;
                }
            }
            
            displayActionDetail(action);
        });
    });
}
