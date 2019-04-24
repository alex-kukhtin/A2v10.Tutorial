

const template = {
	validators: {
		"Agent.Name":
			[{ valid:isNameValid, msg:'empty field' }]
	},
	events: {
		"Model.load": modelLoad
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