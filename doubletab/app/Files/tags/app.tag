<app class="column grow" onmouseover={ setBackground } onmouseout={ removeBackground }>
	<div id="titleBar" class="row row-items-stretch no-shrink" onmousedown={ moveWindow }>
		<div class="row half">
			<h5 class="window-info">Double Tab</h5>
		</div>
		<div class="row-right row-items-middle half">
			<img src="assets/images/minimize.svg" class="window-control" onclick={ minimizeWindow }>
			<img src="assets/images/close.svg" class="window-control" onclick={ closeWindow }>
		</div>
	</div>
	<div id="content" class="column grow">
		<div id="loading" if={ loading }></div>
		<div class="row-center row-items-middle grow" if={ !loading && (!players.CT.length && !players.T.length) }>
			<h1>Waiting for players...</h1>
		</div>
		<div id="playersData" class="row grow" if={ players.CT.length || players.T.length }>
			<div class="column half">
				<profile each={ players.CT } team="CT"></profile>
			</div>
			<div class="column half">
				<profile each={ players.T } team="T"></profile>
			</div>
		</div>
	</div>
	<div id="ad" class="row-center row-items-middle no-shrink"></div>
	<div id="statusBar" class="row no-shrink">
		<div class="row grow">
			<p class="window-info">The ads in the app allows me to keep it 100% free and still pay the bills.</p>
		</div>
		<div class="row-right">
			<img id="resizeButton" src="assets/images/resize.svg" class="window-control" onmousedown={ resizeWindow }>
		</div>
	</div>

	<style>
		app {
			background: rgba(0, 0, 0, 0.5);
			transition: background-color 1.5s ease;
		}
		app.mouse-out {
			background: rgba(0, 0, 0, 0.004);
		}
		app.mouse-out .window-control, app.mouse-out .window-info {
			opacity: 0;
		}
		#content {
			position: relative;
		}
		#playersData {
			overflow: hidden;
			overflow-y: auto;
			margin: 0 10px;
			padding-right: 5px;
		}
		#loading {
			position: absolute;
			top: 0;
			left: 0;
			width: 100%;
			height: 100%;
			z-index: 1000;
			background: transparent url(assets/images/loading.svg) no-repeat center center;
		}
		#titleBar, #statusBar, #ad {
			z-index: 500;
		}
		#titleBar, #statusBar {
			padding: 10px;
		}
		#ad {
			min-height: 90px;
			padding-top: 10px;
		}
		#resizeButton {
			cursor: nw-resize;
		}
		.window-control, .window-info {
			opacity: 1;
			transition: opacity 1.5s ease;
		}
		.window-control {
			width: 15px;
			height: 15px;
			margin-left: 10px;
			cursor: pointer;
		}
	</style>

	<script>
		var self = this;
		var appElement = this.root;
		var windowODK;

		var hotkeyThreshold = 500;
		var hotkeyCount = 0;
		var hotkeyTimeout;

		var lastMatchData = '';

		this.players = {
			CT: [],
			T: []
		}
		this.loading = false;

		this.on('mount', () => {
			var myOverwolfAd = new OwAd(appElement.querySelector('#ad'), { size: { width: 728, height: 90 }});
			myOverwolfAd.addEventListener('display_ad_loaded', () => console.log('Ads loaded successfully.'));
		});

		q(overwolf.windows.getCurrentWindow)
			.then(result => {
				windowODK = result.window;
				centerWindow();
			});

		moveWindow() { overwolf.windows.dragMove(windowODK.id); }
		closeWindow() { overwolf.windows.close(windowODK.id); }
		resizeWindow() { overwolf.windows.dragResize(windowODK.id, 'BottomRight'); }
		minimizeWindow() { overwolf.windows.minimize(windowODK.id); }

		setBackground() {
			appElement.classList.toggle('mouse-out', false);
		}

		removeBackground() {
			if (!this.players.CT.length && !this.players.T.length) return;
			appElement.classList.toggle('mouse-out', true);
		}

		overwolf.games.onGameLaunched.addListener(onGameLaunched);
		overwolf.games.onGameInfoUpdated.addListener(onGameInfoUpdated);
		overwolf.games.events.onInfoUpdates2.addListener(onInfoUpdates);

		overwolf.settings.registerHotKey('toggle', result => {
			if (result.error) return;

			q(overwolf.windows.getWindowState, windowODK.id)
				.then(result => {
					if (result.window_state === 'minimized' && (++hotkeyCount === 2)) {
						hotkeyCount = 0;
						overwolf.windows.restore(windowODK.id);
					} else {
						overwolf.windows.minimize(windowODK.id);
					}
				});

			if (hotkeyTimeout) clearTimeout(hotkeyTimeout);
			hotkeyTimeout = setTimeout(() => {
				hotkeyCount = 0;
				hotkeyTimeout = undefined;
			}, hotkeyThreshold);
		});

		init();

		function init() {
			console.log('Initializing...');
			getRunningGameInfo()
				.then(game => {
					if (game.id !== 77641) return console.log('CSGO is not detected.');

					console.log('CSGO detected.');

					setRequiredFeatures()
						.then(updatePlayersStats)
						.catch(errorHandler.bind(this, true));
				})
				.catch(() => {
					console.log('No game detected.');
				});

			setTimeout(window.loadPlayers, 5000);
		}

		function centerWindow() {
			var left = parseInt(window.screen.width / 2 - window.innerWidth / 2);
			var top = parseInt(window.screen.height / 2 - window.innerHeight / 2);

			overwolf.games.getRunningGameInfo(info => {
				if (info && info.isInFocus) {
					left = parseInt(info.width / 2 - window.innerWidth / 2);
					top = parseInt(info.height / 2 - window.innerHeight / 2);
				}

				overwolf.windows.changePosition(windowODK.id, left, top);
			});
		}

		function errorHandler(informUser, err) {
			var msg = (err instanceof Error ? err.message : err);
			if (informUser) swal({ title: '', text: msg, type: 'error' });
			console.error(msg);
			self.loading = false;
			self.update();
		}

		function getRunningGameInfo() {
			return new Promise((resolve, reject) => {
				console.log('Getting running game info.');
				overwolf.games.getRunningGameInfo(game => {
					if (game) resolve(game);
					else reject(new Error('No supported game detected.'));
				});
			});
		}

		function setRequiredFeatures() {
			return new Promise((resolve, reject) => {

				var tryToSetRequiredFeatures = () => {
					console.log('Trying to set required features.');
					q(overwolf.games.events.setRequiredFeatures, ['roster'])
						.then(result => {
							if (result.supportedFeatures.length) {
								console.log('Required features set.');
								openNotificationWindow();
								resolve();
							} else {
								var msg = 'Roster event is not yet supported by Overwolf. Maybe you are running an older version of Overwolf, or the event has been disabled for some reason.';
								reject(new Error(msg));
							}
						})
						.catch(err => {
							console.log('Required features could not be set. Retrying in 5 seconds.');
							setTimeout(tryToSetRequiredFeatures, 5000);
						});
				};

				tryToSetRequiredFeatures();

			});
		}

		function updatePlayersStats() {
			overwolf.games.events.getInfo(result => {
				if ((result.status === 'status' || result.status === 'success') && result.res && result.res.roster && result.res.roster.match) {
					var matchData = result.res.roster.match;
					console.log('Trying to parse match data.', matchData);
					try {
						matchData = JSON.parse(matchData);
						console.log('Match data parsed.', matchData);
					} catch (err) {
						return errorHandler(true, 'Match data could not be parsed.');
					}
					if (matchData && matchData.players && matchData.players.length) {
						matchData.players = matchData.players.filter(player => {
							var result = true;

							switch (player.steamId) {
								case "0":
								case "76561197960265729":
								case "76561197960265730":
								case "76561197960265731":
								case "76561197960265732":
								case "76561197960265733":
								case "76561197960265734":
								case "76561197960265735":
								case "76561197960265736":
									result = false;
									break;
							}

							return result;
						});

						if (!matchData.players.length) return console.log('No players detected.');
						if (JSON.stringify(matchData) === lastMatchData) return console.log('Nothing to update.');
						lastMatchData = JSON.stringify(matchData);

						self.loading = true;
						self.update();
						getPlayersData(matchData)
							.then(players => {
								console.log('Players stats received.', players);
								if (!self.players.CT.length || !self.players.T.length) appElement.classList.toggle('mouse-out', true);
								self.players = players;
								self.loading = false;
								self.update();
							})
							.catch(err => {
								var msg = err.message;
								switch (err.message) {
									case 'Failed to fetch':
										msg = 'There was an error while fetching the players data from the server, possibly the server is down or being maintained.';
										break;
								}
								errorHandler(true, msg);
							});
					} else {
						console.log('No players detected.');
					}
				} else {
					console.log('Roster data is not available.');
				}
			});
		}

		function getPlayersData(matchData) {
			return new Promise((resolve, reject) => {

				var headers = new Headers();
				headers.append('Content-Type', 'application/json');

				var opts = {
					method: 'POST',
					headers: headers,
					body: JSON.stringify(matchData)
				};

				console.log('Trying to get player data from server.');
				fetch('http://138.197.88.76:3000/getPlayersStats', opts)
					.then(res => {
						if (res.ok) return res.json();
						else throw new Error(`${res.status} - ${res.statusText}.`);
					})
					.then(resolve)
					.catch(reject);
			});
		}

		function openNotificationWindow() {
			if (localStorage.getItem('dontShowMeAgain')) return;

			q(overwolf.settings.getHotKey, 'toggle')
				.then(result => {
					if (result.hotkey !== 'unassigned')
						q(overwolf.windows.obtainDeclaredWindow, 'NotificationWindow')
							.then(result => {
								overwolf.windows.restore(result.window.id);
							});
				});

		}

		function onGameLaunched(game) {
			if (!game || game.id !== 77641) return;

			console.log('CSGO launched.');
			setRequiredFeatures()
				.catch(errorHandler.bind(this, true));
		}

		function onInfoUpdates(event) {
			if (event.feature !== 'roster') return;

			updatePlayersStats();
		}

		function onGameInfoUpdated(game) {
			if (!game) return;

			if (game.runningChanged) self.closeWindow();
			if (game.resolutionChanged || game.focusChanged) centerWindow();
		}

	</script>
</app>