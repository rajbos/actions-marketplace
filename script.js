var jsonFileToUrl = 'actions-data-url.txt';
var jsonUrl = 'actions-data.json';
var allActions = [];
var activeFilters = {};

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
    panel.setAttribute('data-is-fork', action.isFork === true ? 'true' : 'false');
    panel.setAttribute('data-is-archived', action.isArchived === true ? 'true' : 'false');
    panel.setAttribute('data-visibility', action.visibility || 'public');
    panel.setAttribute('data-using', action.using || 'unknown');
    
    // Determine visibility status
    var isPrivate = action.private === true;
    var visibilityClass = isPrivate ? 'visibility-badge-private' : 'visibility-badge-public';
    var visibilityText = isPrivate ? 'Private' : 'Public';
    var visibilityIcon = isPrivate ? '🔒' : '🌐';
    
    panel.innerHTML = `<div class="line"><span class="name">Repository:</span><span class="value"><a href="https://github.com/${action.owner}/${action.repo}">${action.repo}</a><span class="visibility-badge ${visibilityClass}">${visibilityIcon} ${visibilityText}</span></span></div>`;
    panel.innerHTML += '<div class="line"><span class="name">Action:</span><span class="value">'+action.name+'</span></div>';
    panel.innerHTML += '<div class="line"><span class="name">Author:</span><span class="value">'+(action.author || "Not set") +'</span></div>';
    panel.innerHTML += '<div class="line"><span class="name">Description:</span><div class="value description">'+action.description+'</div></div>';
    panel.innerHTML += '<div class="panel-actions"><a href="detail.html?repo='+encodeURIComponent(action.repo)+'">View Details →</a></div>';

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
        
        // Check search term match
        var searchMatches = searchLower === '' || 
                     name.indexOf(searchLower) !== -1 || 
                     repo.indexOf(searchLower) !== -1 || 
                     author.indexOf(searchLower) !== -1 || 
                     description.indexOf(searchLower) !== -1;
        
        // Check filter matches
        var filterMatches = true;
        for (var filterKey in activeFilters) {
            var filterValue = activeFilters[filterKey];
            var attrName = 'data-' + convertFilterKeyToAttrName(filterKey);
            var panelValue = panel.getAttribute(attrName) || '';
            
            // Special handling for "using" filter - check if value starts with the filter term
            if (filterKey === 'using') {
                var lowerPanelValue = panelValue.toLowerCase();
                // Match if the value starts with the filter (e.g., 'node16' starts with 'node', 'composite' starts with 'composite')
                if (lowerPanelValue.indexOf(filterValue) !== 0) {
                    filterMatches = false;
                    break;
                }
            } else {
                // Exact match for other filters
                if (panelValue !== filterValue) {
                    filterMatches = false;
                    break;
                }
            }
        }
        
        if (searchMatches && filterMatches) {
            panel.style.display = 'block';
            visibleCount++;
        } else {
            panel.style.display = 'none';
        }
    });
    
    var actionCountElement = document.getElementById('actionCount');
    actionCountElement.innerHTML = visibleCount;
}

function convertFilterKeyToAttrName(filterKey) {
    // Convert camelCase filter keys to kebab-case data attribute names
    var attrMap = {
        'isFork': 'is-fork',
        'isArchived': 'is-archived',
        'visibility': 'visibility',
        'using': 'using'
    };
    return attrMap[filterKey] || filterKey.toLowerCase();
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

function updateFilterCounts() {
    var counts = {
        'count-fork': 0,
        'count-not-fork': 0,
        'count-active': 0,
        'count-archived': 0,
        'count-public': 0,
        'count-private': 0,
        'count-composite': 0,
        'count-node': 0,
        'count-docker': 0
    };
    
    allActions.forEach(function(action) {
        if (action.isFork === true) {
            counts['count-fork']++;
        } else {
            counts['count-not-fork']++;
        }
        
        if (action.isArchived === true) {
            counts['count-archived']++;
        } else {
            counts['count-active']++;
        }
        
        if (action.visibility === 'private') {
            counts['count-private']++;
        } else {
            counts['count-public']++;
        }
        
        var using = (action.using || 'unknown').toLowerCase();
        if (using.indexOf('composite') === 0) {
            counts['count-composite']++;
        } else if (using.indexOf('node') === 0) {
            counts['count-node']++;
        } else if (using.indexOf('docker') === 0) {
            counts['count-docker']++;
        }
    });
    
    for (var key in counts) {
        var element = document.getElementById(key);
        if (element) {
            element.innerHTML = counts[key];
        }
    }
}

function toggleFilter(filterKey, filterValue) {
    var button = document.querySelector('.filter-btn[data-filter="' + filterKey + '"][data-value="' + filterValue + '"]');
    
    if (activeFilters[filterKey] === filterValue) {
        // Remove filter if clicking the same one
        delete activeFilters[filterKey];
        button.classList.remove('active');
    } else {
        // Remove active class from all buttons in the same filter group
        var groupButtons = document.querySelectorAll('.filter-btn[data-filter="' + filterKey + '"]');
        groupButtons.forEach(function(btn) {
            btn.classList.remove('active');
        });
        
        // Set new filter
        activeFilters[filterKey] = filterValue;
        button.classList.add('active');
    }
    
    // Reapply filters
    var searchInput = document.querySelector('.search input');
    filterActions(searchInput.value);
}

function clearAllFilters() {
    activeFilters = {};
    
    // Remove active class from all filter buttons
    var buttons = document.querySelectorAll('.filter-btn');
    buttons.forEach(function(btn) {
        btn.classList.remove('active');
    });
    
    // Clear search and reapply
    var searchInput = document.querySelector('.search input');
    filterActions(searchInput ? searchInput.value : '');
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
            
            // Update filter counts
            updateFilterCounts();
            
            // Setup search functionality
            var searchInput = document.querySelector('.search input');
            searchInput.addEventListener('input', function(e) {
                filterActions(e.target.value);
            });
            
            // Setup filter button functionality
            var filterButtons = document.querySelectorAll('.filter-btn');
            filterButtons.forEach(function(btn) {
                btn.addEventListener('click', function() {
                    var filterKey = this.getAttribute('data-filter');
                    var filterValue = this.getAttribute('data-value');
                    toggleFilter(filterKey, filterValue);
                });
            });
            
            // Setup clear filters button
            var clearBtn = document.getElementById('clearFiltersBtn');
            if (clearBtn) {
                clearBtn.addEventListener('click', clearAllFilters);
            }
        }
        )}
    )
}
    
