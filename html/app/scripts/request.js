'use strict';

/**
 * Called when the user either clicks the URL request button or presses
 * enter on it.
 */
function requestUrl() {
    var elem = document.getElementById('urlinput'),
        url = elem.value;

    if (url.length === 0) { return; }

    gmod.requestUrl(url);
}

/**
 * Called when the user presses a key while focused on the URL input
 * text box.
 *
 * @param  {KeyboardEvent} event Keyboard event.
 */
function onUrlKeyDown(event) {
    var key = event.keyCode || event.which;

    // submit request when the enter key is pressed
    if (key === 13) {
        requestUrl();
    }
}

/**
 * Called when a user hovers over a service icon.
 */
function hoverService() {
    console.log( 'PLAY: garrysmod/ui_hover.wav' );
}

/**
 * Called when a user selects a service to navigate to.
 *
 * @param  {HTMLElement} elem DOM element.
 */
function selectService(elem) {
    console.log( 'PLAY: garrysmod/ui_click.wav' );

    var href = elem.dataset.href,
        overlay = (elem.dataset.overlay !== undefined);

    if (overlay) {
        gmod.openUrl(href);
    } else {
        window.location.href = href;
    }
}

(function(gmod) {
    if (gmod === undefined) { return; }

    window.setServices = function (serviceIds) {
        serviceIds = serviceIds.split(',');

        var elem, sid;
        var serviceElems = document.querySelectorAll('.media-service');

        for (var i = 0; i < serviceElems.length; i++) {
            elem = serviceElems[i];
            sid = elem.dataset.service;
            if (!sid) { continue; }

            sid = sid.split(' ');

            // hide all service icons which aren't supported
            for (var j = 0; j < sid.length; j++) {
                if (serviceIds.indexOf(sid[j]) === -1) {
                    elem.style.display = 'none';
                }
            }
        }
    };

    gmod.getServices();
}(window.gmod));
