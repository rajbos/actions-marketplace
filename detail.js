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

function escapeHtml(text) {
    if (!text) return '';
    var div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function displayActionDetail(action) {
    var detailElement = document.getElementById('actionDetail');
    
    if (!action) {
        detailElement.innerHTML = '<div class="detail-error">Action not found. <a href="index.html">Return to marketplace</a></div>';
        return;
    }

    // Determine visibility status
    var visibility = action.visibility || (action.private === true ? 'private' : 'public');
    var visibilityClass = 'visibility-badge-public';
    var visibilityIcon = '🌐';
    
    if (visibility === 'private') {
        visibilityClass = 'visibility-badge-private';
        visibilityIcon = '🔒';
    } else if (visibility === 'internal') {
        visibilityClass = 'visibility-badge-internal';
        visibilityIcon = '🏢';
    }
    
    var visibilityText = visibility.charAt(0).toUpperCase() + visibility.slice(1);
    
    var html = '<div class="detail-header">';
    html += '<h2>' + escapeHtml(action.name) + '</h2>';
    html += '<span class="visibility-badge ' + visibilityClass + '">' + visibilityIcon + ' ' + visibilityText + '</span>';
    
    // Add archived badge if applicable
    if (action.isArchived) {
        html += '<span class="visibility-badge visibility-badge-archived">📦 Archived</span>';
    }
    
    // Add fork badge if applicable
    if (action.isFork) {
        html += '<span class="visibility-badge visibility-badge-fork">🔱 Fork</span>';
    }
    
    html += '</div>';
    
    html += '<div class="detail-section">';
    html += '<h3>Repository</h3>';
    var ownerName = escapeHtml(action.owner || '');
    var repoName = escapeHtml(action.repo);
    html += '<p><a href="https://github.com/' + ownerName + '/' + repoName + '" target="_blank">' + ownerName + '/' + repoName + '</a></p>';
    html += '</div>';
    
    if (action.path) {
        html += '<div class="detail-section">';
        html += '<h3>Path</h3>';
        html += '<p>' + escapeHtml(action.path) + '</p>';
        html += '</div>';
    }
    
    if (action.author) {
        html += '<div class="detail-section">';
        html += '<h3>Author</h3>';
        html += '<p>' + escapeHtml(action.author) + '</p>';
        html += '</div>';
    }
    
    html += '<div class="detail-section">';
    html += '<h3>Description</h3>';
    html += '<p>' + escapeHtml(action.description) + '</p>';
    html += '</div>';
    
    if (action.using && action.using !== '') {
        html += '<div class="detail-section">';
        html += '<h3>Runtime</h3>';
        var runtimeText = escapeHtml(action.using);
        runtimeText = runtimeText.charAt(0).toUpperCase() + runtimeText.slice(1);
        html += '<p>' + runtimeText + '</p>';
        html += '</div>';
    }
    
    if (action.forkedfrom && action.forkedfrom !== '') {
        // Validate format: owner/repo (basic check)
        var escapedForkedFrom = escapeHtml(action.forkedfrom);
        var parts = escapedForkedFrom.split('/');
        if (parts.length === 2 && parts[0].length > 0 && parts[1].length > 0) {
            html += '<div class="detail-section">';
            html += '<h3>Forked From</h3>';
            html += '<p><a href="https://github.com/' + escapedForkedFrom + '" target="_blank">' + escapedForkedFrom + '</a></p>';
            html += '</div>';
        }
    }
    
    if (action.downloadUrl) {
        html += '<div class="detail-section">';
        html += '<h3>Action File</h3>';
        html += '<p><a href="' + escapeHtml(action.downloadUrl) + '" target="_blank">View action.yml</a></p>';
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
