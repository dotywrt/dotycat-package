'use strict';
'require form';
'require fs';
'require rpc';
'require uci';
'require ui';
'require view';


return view.extend({
	load: function() {
		return Promise.all([
			uci.load('rtawrt')
		]);
	},

	render: function(data) {
		var m, s, o;

		m = new form.Map('rtawrt', _('RTA-WRT theme configuration'),
			_('Here you can set rtawrt theme. Chrome is recommended.'));

		s = m.section(form.TypedSection, 'global', _('Theme configuration'));
		s.addremove = false;
		s.anonymous = true;

		o = s.option(form.ListValue, 'mode', _('Theme mode'));
		o.value('normal', _('Follow system'));
		o.value('light', _('Light mode'));
		o.value('dark', _('Dark mode'));
		o.default = 'normal';
		o.rmempty = false;

		o = s.option(form.Button, '_save', _('Save settings'));
		o.inputstyle = 'apply';
		o.inputtitle = _('Save current settings');
		o.onclick = function() {
			ui.changes.apply(true);
			return this.map.save(null, true);
		}

		return m.render();
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});