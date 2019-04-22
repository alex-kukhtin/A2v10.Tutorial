

const template = {
	validators: {
		"Agent.Name":
			[{ valid:isNameValid, msg:'empty field' }]
	}
};

module.exports = template;


function isNameValid(agent) {
	console.dir(agent);
	return agent.Name.length > 3;
}