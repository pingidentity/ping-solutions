afterEach(() => {
	cy.window().then(win => {
		if (typeof win.gc === 'function') {
			// calling this more often seems to trigger major GC event more reliably
			win.gc(); win.gc(); win.gc(); win.gc(); win.gc();
		}
	});
});