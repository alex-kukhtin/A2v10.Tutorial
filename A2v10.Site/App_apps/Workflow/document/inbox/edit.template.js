

const template = {
	properties: {
	},
	delegates: {
	},
	commands: {
		resume
	}
};

module.exports = template;

async function resume(arg) {
	const ctrl = this.$ctrl;
	await ctrl.$invoke('resume', {Id: this.Inbox.Id, Answer: arg});
	this.$vm.$close();
}