const template = {
	validators: {
		"Entity.Name":
			[{ valid:isNameValid, msg:'Слишком пусто' }]
	}
};

module.exports = template;

function isNameValid(entity) {
	console.dir(entity);
	return entity.Name.length > 5;
}