

window.navigator.geolocation.getCurrentPosition(function (pos) {
	var currPos = { lat: pos.coords.latitude, lng: pos.coords.longitude };
	var map = new google.maps.Map(document.getElementById('gmapapi'), {
		center: currPos,
		zoom: 15
	});
	var marker = new google.maps.Marker({ position: currPos, map: map });
});
