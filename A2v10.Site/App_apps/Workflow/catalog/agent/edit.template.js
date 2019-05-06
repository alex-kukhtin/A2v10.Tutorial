

const template = {
	properties: {
		'TAgent.$Fr': Boolean,
		'TAgent.$MapUrl': getMapUrl
	},
	validators: {
		"Agent.Name":
			[{ valid:isNameValid, msg:'empty field. @[Reload] needed!' }]
	},
	events: {
		"Model.load": modelLoad
	},
	commands: {
		getPos,
		addMarker
	}
};

module.exports = template;


function isNameValid(agent) {
	console.dir(agent);
	return agent.Name.length > 3;
}

function modelLoad(root) {
	if (root.Params.Text) {
		root.Agent.Name = root.Params.Text;
		root.$defer(() => {
			root.$setDirty(true);
		});
	}
	showGmapApi();
	console.dir(window.google.maps);
}

function getPos() {
	console.dir(navigator.geolocation);
	navigator.geolocation.getCurrentPosition(function (pos) {
		console.dir(pos);
	});
	alert('got!');
}

let currentMap;
let currPos;

function showGmapApi() {
	window.navigator.geolocation.getCurrentPosition(function (pos) {
		currPos = { lat: pos.coords.latitude, lng: pos.coords.longitude };
		var map = new google.maps.Map(document.getElementById('gmapapi'), {
			center: currPos,
			zoom: 15
		});
		currentMap = map;
		var marker = new google.maps.Marker({ position: currPos, map: map });
		drawOsm(currPos);
	});
}

function addMarker() {
	currPos = { lat: currPos.lat + 0.001, lng: currPos.lng - 0.001 };
	var marker2 = new google.maps.Marker({ position: currPos, map: currentMap });
}

function getMapUrl() {
	if (this.$Fr)
		return 'https://www.google.com/maps/embed/v1/place?key=@{AppSettings.GoogleMapsApiKey}&q=Eiffel+Tower,Paris+France&language=fr&region=FR';
	else
		return 'https://www.google.com/maps/embed/v1/place?key=@{AppSettings.GoogleMapsApiKey}&q=Eiffel+Tower,Paris+France&language=uk&region=UA';
}


function drawOsm(pos) {
	var map = new OpenLayers.Map("osm");
	map.addLayer(new OpenLayers.Layer.OSM());

	var lonLat = new OpenLayers.LonLat(pos.lng, pos.lat)
		.transform(
			new OpenLayers.Projection("EPSG:4326"), // transform from WGS 1984
			map.getProjectionObject() // to Spherical Mercator Projection
		);

	var zoom = 16;
	console.dir(map.size);

	var markers = new OpenLayers.Layer.Markers("Markers");
	map.addLayer(markers);

	markers.addMarker(new OpenLayers.Marker(lonLat));

	map.setCenter(lonLat, zoom);
}