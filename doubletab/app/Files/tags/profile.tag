<profile class="row row-items-stretch" ondblclick={ openProfile }>
	<div class="profile-avatar">
		<img class="avatar" src={ avatarFull } onload={ avatarLoaded }>
		<img class={ flagClasses } if={ countryCode }>
	</div>
	<div class="profile-data column grow">
		<h5 class="profile-name">{ personaName }</h5>
		<div class="profile-private row-center row-items-middle" if={ !stats }>
			<p>-[ PRIVATE PROFILE ]-</p>
		</div>
		<div class="profile-stats row-space-between row-items-stretch grow" if={ stats }>
			<div class="column profile-fav-weapon" if={ favWeapon }>
				<p class="csgo csgo-2x csgo-{ favWeapon } grow"></p>
				<p class="stat-label" style="text-align: left">{ favWeapon }</p>
			</div>
			<div class="column" if={ kdr }>
				<p class="stat-data">{ kdr }</p>
				<p class="stat-label">KDR</p>
			</div>
			<div class="column" if={ kpm }>
				<p class="stat-data">{ kpm }</p>
				<p class="stat-label">KPM</p>
			</div>
			<div class="column" if={ accuracy }>
				<p class="stat-data">{ accuracy }%</p>
				<p class="stat-label">ACCURACY</p>
			</div>
			<div class="column" if={ headshots }>
				<p class="stat-data">{ headshots }%</p>
				<p class="stat-label">HEADSHOTS</p>
			</div>
			<div class="column" if={ wins }>
				<p class="stat-data">{ wins }%</p>
				<p class="stat-label">WINS</p>
			</div>
			<div class="column" if={ time }>
				<p class="stat-data">{ time }h</p>
				<p class="stat-label" style="text-align: right">TIME</p>
			</div>
		</div>
	</div>

	<style>
		profile {
			margin-bottom: 4px;
			cursor: pointer;
		}
		profile[team=CT] {
			color: #7E8388;
		}
		profile[team=T] {
			color: #8C8170;
		}
		profile[team=T] .profile-avatar {
			order: 1;
			margin: 0 0 0 4px;
		}
		profile[team=CT] .profile-name, profile[team=CT] .stat-data, profile[team=CT] .csgo {
			color: #BCC2C8;
		}
		profile[team=T] .profile-name, profile[team=T] .stat-data, profile[team=T] .csgo {
			color: #CDC1B0;
		}
		profile[team=CT] .profile-data {
			background-color: rgba(22, 28, 35, 0.95);
			border: 2px solid;
			border-image: linear-gradient(#4a575f, #161c23) 1;
		}
		profile[team=T] .profile-data {
			background-color: rgba(53, 41, 25, 0.95);
			border: 2px solid;
			border-image: linear-gradient(#4E412A, #352919) 1;
		}
		.profile-avatar {
			position: relative;
			box-sizing: border-box;
			width: 64px;
			margin: 0 4px 0 0;
			background: #222 url(assets/images/loading2.svg) no-repeat center center;
			background-size: contain;
			border: 2px solid;
			border-image: linear-gradient(#7B7B7B, #2A2A2A) 1;
			box-shadow: 0 0 2px #101316;
		}
		.profile-avatar .avatar {
			width: 100%;
			height: 100%;
			object-fit: cover;
			opacity: 0;
			transition: opacity 1s ease;
		}
		.profile-avatar .flag {
			position: absolute;
			right: 0;
			bottom: 0;
		}
		.profile-name, .profile-stats {
			padding: 4px;
		}
		.profile-name {
			background: linear-gradient(transparent, rgba(255, 255, 255, 0.05));
			text-align: center;
		}
		.profile-private {
			height: 39px;
		}
		.stat-data, .stat-label {
			text-align: center;
		}
		.stat-data {
			margin-bottom: 1em;
			flex-grow: 1;
		}
		.stat-label {
			font-size: .7em;
			text-transform: uppercase;
		}
	</style>

	<script>
		var self = this;
		this.flagClasses = { flag: true };

		avatarLoaded() {
			this.root.querySelector('.profile-avatar').style.backgroundImage = 'none';
			this.root.querySelector('.avatar').style.opacity = 1;
		}

		openProfile() {
			if (!this.profileUrl) return;
			overwolf.utils.openUrlInOverwolfBrowser(this.profileUrl);
		}

		init();

		function init() {
			if (self.countryCode) self.flagClasses['flag-' + self.countryCode.toLowerCase()] = true;
			if (self.stats) {
				self.favWeapon = getFavWeapon();
				self.kdr = Number(getStat('total_kills') / getStat('total_deaths')).toFixed(2);
				self.kpm = Number(getStat('total_time_played') / 60 / getStat('total_kills')).toFixed(2);
				self.accuracy = Number(getStat('total_shots_hit') / getStat('total_shots_fired')).toFixed(2).slice(2);
				self.headshots = Number(getStat('total_kills_headshot') / getStat('total_kills')).toFixed(2).slice(2);
				self.wins = Number(getStat('total_matches_won') / getStat('total_matches_played')).toFixed(2).slice(2);
				self.time = Number(getStat('total_time_played') / 60 / 60).toFixed(0);
			}
		}

		function getStat(name) {
			return self.stats.filter(stat => stat.name === name)[0].value;
		}

		function getFavWeapon() {
			var name = self.stats.filter(stat => {
				switch (stat.name) {
					case 'total_kills_hegrenade':
					case 'total_kills_molotov':
					case 'total_kills_taser':
					case 'total_kills_headshot':
					case 'total_kills_enemy_weapon':
					case 'total_kills_enemy_blinded':
					case 'total_kills_knife_fight':
					case 'total_kills_against_zoomed_sniper':
						return false;
				}
				return stat.name.match(/^total_kills_/);
			})
			.sort((a, b) => {
				return b.value - a.value;
			})[0].name

			return name.substr(name.lastIndexOf('_') + 1);
		}
	</script>
</profile>