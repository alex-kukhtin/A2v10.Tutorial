

const template = {
	properties: {
		'TDocument.$Radio': String,
		"TDocument.$Sum": function () {
			return this.Rows.reduce((p, c) => p + c.Sum, 0);
		},
		"TRow.Sum": {
			get: function () {
				return this.Qty * this.Price;
			},
			set: function (value) {
				this.Price = value / this.Qty;
			}
		}
	},
	delegates: {
		fetchSupplier
	},
	commands: {
		newSupplier,
		startProcess
	}
};

module.exports = template;

function fetchSupplier(agent, text) {
	const ctrl = this.$ctrl;
	return ctrl.$invoke('fetchSupplier', { Text: text }, '/catalog/agent');
	//return [];
}

function newSupplier(opts) {
	const ctrl = this.$ctrl;
	ctrl.$showDialog('/catalog/agent/edit', { Id: 0 }, { Text: opts.text }).then(function (ag) {
		console.dir(ag);
		opts.elem.$merge(ag);
	});
}

async function startProcess(doc) {
	let ctrl = this.$ctrl;
	let result = await ctrl.$invoke('startProcess', { Id: doc.Id });
	console.dir(result);
	this.$vm.$toast({ text: 'Workflow start successfully', style: 'success' });
}