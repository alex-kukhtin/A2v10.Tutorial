

const template = {
	validators: {
		"Agent.Name":
			[{ valid:isNameValid, msg:'empty field. @[Reload] needed!' }]
	},
	events: {
		"Model.load": modelLoad
	},
	commands: {
		getPos
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
}

function getPos() {
	console.dir(navigator.geolocation);
	navigator.geolocation.getCurrentPosition(function (pos) {
		console.dir(pos);
	});
	alert('got!')
}