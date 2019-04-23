

const template = {
	properties: {
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
	}
};

module.exports = template;


