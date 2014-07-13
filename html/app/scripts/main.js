'use strict';

window.MP = (function () {

	var elem = document.body;

	return {

		setHtml: function (html) {
			elem.innerHTML = html;
			console.log(elem.innerHTML);
		}

	};

}());
