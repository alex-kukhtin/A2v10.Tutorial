

const template = {
	properties: {
		'TAgent.$CapsName'() { return this.Name.toUpperCase();}
	},
	commands: {
		addElem
	}
}


module.exports = template;


function addElem(coll) {
	console.dir(coll);
	coll.$prepend({ Name: 'new element' });
}