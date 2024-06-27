class Task
{
	constructor(type, scope)
	{
		this.type = type;
		Object.defineProperties(this, {
			world: {
				get: () => scope.worlds[scope.selectedWorld].name,
				enumerable: true
			},
			generateMode: {
				get: () => scope.generateMode,
				enumerable: true
			},
			chunkOrder: {
				get: () => scope.chunkOrder,
				enumerable: true
			}
		})
	}
	type = null;
}


class FixedChunkTask extends Task
{
	constructor(scope)
	{
		super("fixed", scope)
	}
	chunkX = 0;
	chunkZ = 0;
	radius = (localStorage.getItem("ChunkRegen.FixedChunkRadius") || 1) * 1;
}

class PlayerTask extends Task
{
	constructor(scope, playerName, radius)
	{
		super("player", scope);
		this.playerName = playerName,
		this.radius = radius;
	}
	playerName;
	radius;
}

Array.prototype.sum = function(prop){
    return this.reduce( function(a, b){
        return a + prop(b);
    }, 0);
};


function refreshCanvas(previewCanvas, previewContext, gridSize, chunkOrder, currentPos)
{
	previewContext.clearRect(0, 0, previewCanvas.width, previewCanvas.height);
	const distanceBetweenSquares = 1;
	const squareSizeX = previewCanvas.width / (gridSize) - distanceBetweenSquares;
	const squareSizeZ = previewCanvas.height / (gridSize) - distanceBetweenSquares;
	// Draw the grid
	for (let x = 0; x < gridSize; x++)
	{
		let renderX = previewCanvas.width / (gridSize) * x + distanceBetweenSquares;
		for (let z = 0; z < gridSize; z++)
		{
			let renderZ = previewCanvas.height / (gridSize) * z + distanceBetweenSquares;
			// let color = g_Colors[this.values[x + z * gridSize]];
			previewContext.fillStyle = "rgba(255, 255, 255, 255)";
			previewContext.fillRect(renderX, renderZ, squareSizeX, squareSizeZ);
		}
	}

	// Draw the chunks up to the current position
	previewContext.fillStyle = "rgba(0, 255, 0, 255)";
	for (let i = 0; i < currentPos; i++)
	{
		let chunk = chunkOrder[i]
		let renderX = previewCanvas.width / (gridSize) * chunk.x + distanceBetweenSquares;
		let renderZ = previewCanvas.height / (gridSize) * chunk.z + distanceBetweenSquares;
		previewContext.fillRect(renderX, renderZ, squareSizeX, squareSizeZ);
	}
}

var app = angular.module("mainApp", []);
app.controller("controller", ($scope, $http, $interval) => {
	let previewCanvas = document.getElementById("preview-canvas");
	let previewContext = previewCanvas.getContext("2d");
	$scope.worlds = [];
	$scope.selectedWorld = null
	$scope.generateMode = GenerateMode.Regenerate
	$scope.generateModeOptions = Object.keys(GenerateMode);
	$scope.chunkOrder = ChunkOrder.Spiral
	$scope.chunkOrderOptions = Object.keys(ChunkOrder);
	$scope.fixedChunk = new FixedChunkTask($scope);
	$scope.activeConnection = false;
	$scope.playerRadius = (localStorage.getItem("ChunkRegen.PlayerRadius") || 1) * 1;
	$scope.previewChunkOrderId = -1
	$scope.previewChunkOrder = false;
	$scope.previewRadius = 5;

	$scope.$watch("[chunkOrder, previewRadius]", () => {
		if (!$scope.previewChunkOrder) {
			return;
		}
		$scope.startPreview()
	})
	$scope.$watch("fixedChunk.radius", () => {
		localStorage.setItem("ChunkRegen.FixedChunkRadius", $scope.fixedChunk.radius)
	});
	$scope.$watch("playerRadius", () => {
		localStorage.setItem("ChunkRegen.PlayerRadius", $scope.playerRadius)
	});
	
	/** Refreshes the world information.
	  * If only one player is online when the page first loads
	  * the world where the player is active is automatically selected.
	  */
	$scope.refreshWorlds = function(firstCall) {
		$http({
			method: "GET",
			url: "?endpoint=worlds"
		}).then(response => {
			$scope.activeConnection = true;
			if (firstCall === true) {
				$scope.worlds = response.data;
				let totalPlayers = response.data.sum(world => world.players?.length || 0)
				if (totalPlayers == 1 && $scope.selectedWorld == null) {
					for (let idx in $scope.worlds) {
						if ($scope.worlds[idx].players?.length == 1) {
							$scope.selectedWorld = idx;
							break;
						}
					}
				}
			}
			else {
				for (let idx in response.data) {
					$scope.worlds[idx].players = response.data[idx].players;
					$scope.worlds[idx].tasks = response.data[idx].tasks;
					$scope.worlds[idx].stats = response.data[idx].stats;
				}
			}
		}, () => {
			$scope.activeConnection = false;
			console.log("Not accessible");
		});
	}
	
	/** Creates a new chunk generation task using the configured coordinates and radius */
	$scope.doFixedChunk = function() {
		$http({
			method: "POST", 
			url: "?endpoint=task&world=" + $scope.worlds[$scope.selectedWorld].name,
			headers: {'Content-Type': 'application/x-www-form-urlencoded'},
			data: "task=" + encodeURIComponent(JSON.stringify($scope.fixedChunk))
		})
	}
	
	/** Creates a new chunk generation task around the requested player */
	$scope.doAroundPlayer = function(playerName) {
		let task = new PlayerTask($scope, playerName, $scope.playerRadius);
		$http({
			method: "POST", 
			url: "?endpoint=task&world=" + $scope.worlds[$scope.selectedWorld].name,
			headers: {'Content-Type': 'application/x-www-form-urlencoded'},
			data: "task=" + encodeURIComponent(JSON.stringify(task))
		})
	}
	
	/** Requests to cancel the selected task. */
	$scope.cancelTask = function(task) {
		$http({
			method: "POST",
			url: "?endpoint=canceltask",
			headers: {'Content-Type': 'application/x-www-form-urlencoded'},
			data: "taskId=" + task.id
		})
	}

	/** Formats a world name based on if it has active tasks and/or players. */
	$scope.formatWorldName = function(world) {
		let name = world.name;
		if ((world.players?.length || 0) > 0) {
			name += " (p)";
		}
		if ((world.tasks?.length || 0) > 0) {
			name += " (t)"
		}
		return name;
	}

	/** Cancels or starts the preview screen which allows the user to see how the 
	 * different chunk orders work.
	 */
	$scope.switchPreview = function()
	{
		$scope.previewChunkOrder = !$scope.previewChunkOrder
		if (!$scope.previewChunkOrder)
		{
			clearInterval($scope.previewChunkOrderId);
			return
		}
		$scope.startPreview();
	}

	/** Requests the chunk order based of the current settings and starts the drawing interval */
	$scope.startPreview = function()
	{
		// Make sure the preview preview animation stopped
		clearInterval($scope.previewChunkOrderId);
		$http({
			method: "GET",
			url: `?endpoint=chunkorderpreview&chunkorder=${$scope.chunkOrder}&radius=${$scope.previewRadius}`
		}).then(response => {
			console.log(response)
			let chunkOrder = response.data
			let currentPos = 0;
			$scope.previewChunkOrderId = setInterval(() => {
				refreshCanvas(previewCanvas, previewContext, $scope.previewRadius * 2 + 1, chunkOrder, currentPos++)
				currentPos = currentPos % chunkOrder.length
			}, 100)
		})
	}
	
	
	$scope.refreshWorlds(true);
	
	// Auto refresh the worlds information every 0.5 seconds.
	$interval($scope.refreshWorlds, 500);
	
	// Resize observer to communicate with the parent window.
	// This code is meant to be used inside an iframe
	// so ajax calls automatically go to the layout-less endpoints.
	const resizeObserver = new ResizeObserver(entries => 
		window.parent.postMessage({height: document.body.scrollHeight })
	)
	resizeObserver.observe(document.body);
});

