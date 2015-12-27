/**
 * Created by Hiren on 27/12/2015.
 */
package flexGridSter
{
	import flash.events.MouseEvent;
	import flash.geom.Point;

	import mx.core.UIComponent;

	import mx.effects.Parallel;
	import mx.graphics.SolidColor;

	import spark.components.BorderContainer;
	import spark.components.Image;
	import spark.effects.Move;

	public class FlexGridStack extends BorderContainer
	{
		[Embed(source="assets/resize.svg")]
		private var _resize:Class;

		[Embed(source="assets/cursor_resize.gif")]
		private var _resizeCursor:Class;

		private var _horizontalGap:Number = 20;
		private var _verticalGap:Number = 20;
		private var _nodeMinWidth:Number = 140;
		private var _nodeMinHeight:Number = 140;
		private var _dropIndicatorColor:uint = 0xDDDDDD;
		private var _dropIndicatorAlpha:Number = 0.5;


		public function get horizontalGap():Number
		{
			return _horizontalGap;
		}

		public function set horizontalGap(value:Number):void
		{
			_horizontalGap = value;
		}

		public function get verticalGap():Number
		{
			return _verticalGap;
		}

		public function set verticalGap(value:Number):void
		{
			_verticalGap = value;
		}

		public function get nodeMinWidth():Number
		{
			return _nodeMinWidth;
		}

		public function set nodeMinWidth(value:Number):void
		{
			_nodeMinWidth = value;
		}

		public function get nodeMinHeight():Number
		{
			return _nodeMinHeight;
		}

		public function set nodeMinHeight(value:Number):void
		{
			_nodeMinHeight = value;
		}

		public function get dropIndicatorColor():uint
		{
			return _dropIndicatorColor;
		}

		public function set dropIndicatorColor(value:uint):void
		{
			_dropIndicatorColor = value;
		}

		public function get dropIndicatorAlpha():Number
		{
			return _dropIndicatorAlpha;
		}

		public function set dropIndicatorAlpha(value:Number):void
		{
			_dropIndicatorAlpha = value;
		}

		private var _dropIndicator:BorderContainer;
		private var _draggedItem:BorderContainer;
		private var _items:Array = [];
		private var _parallel:Parallel = new Parallel();
		private var _dropPoints:Point;
		private var _animations:Array = [];
		private var _pods:Array = [];

		public function FlexGridStack()
		{
			super();
		}

		public function addNode(node:UIComponent, width:int, height:int, row:int = 0, column:int = 0):void
		{
			var item:BorderContainer = getBorderContainer(width, height);
			var len:Number = _items.length;
			var isHit:Boolean = false;
			if (row != 0 || column != 0)
			{
				item.x = ((column -1) * _nodeMinWidth) + ((column - 1) * _horizontalGap);
				item.y = ((row -1) * _nodeMinHeight) + ((row - 1) * _verticalGap);
			}
			else
			{
				do {


					for (var j:int = 0; j < len; j++)
					{
						var currElement:BorderContainer = _items[j] as BorderContainer;
						isHit = checkOverlap(item, currElement);
						if (isHit)
						{
							item.x = currElement.x + currElement.width + _horizontalGap;
							if (item.x + item.width > this.width)
							{
								item.x = 0;
								item.y = currElement.y + currElement.height + _verticalGap;
							}
							break;
						}
					}
				} while (isHit);
				updateNodeYPos(item);
			}
			var dropIndicator:BorderContainer = getDropIndicator(item);
			dropIndicator.x = item.x;
			dropIndicator.y = item.y;
			dropIndicator.visible = false;
			this.addElement(dropIndicator);
			_items.push(dropIndicator);

			item.addElementAt(node, 0);
			this.addElement(item);
			_pods.push(item);
		}

		private function getBorderContainer(width:Number, height:Number):BorderContainer
		{
			var container:BorderContainer = new BorderContainer();
			container.setStyle("borderVisible", false);
			container.height = _nodeMinHeight * int(height) + (_verticalGap * (int(height) - 1));
			container.width = _nodeMinWidth * int(width) + (_horizontalGap * (int(width) - 1));
			container.addEventListener(MouseEvent.MOUSE_DOWN, node_mouseDownHandler, false, 5, true);
			container.addEventListener(MouseEvent.MOUSE_UP, node_mouseUpHandler);
			container.addEventListener(MouseEvent.MOUSE_OVER, node_rollOverHandler);
			container.addEventListener(MouseEvent.MOUSE_OUT, node_rollOutHandler);
			var img:Image = new Image();
			img.source = _resize;
			img.bottom = 4;
			img.right = 4;
			img.visible = false;
			img.enabled = false;
			container.addElement(img);
			return container;
		}

		private function node_mouseDownHandler(event:MouseEvent):void
		{
			var targetItem:BorderContainer = event.currentTarget as BorderContainer;
			_draggedItem = targetItem;
			_dropIndicator = _items[_pods.indexOf(_draggedItem)];
			this.setElementIndex(_dropIndicator, 0);
			this.setElementIndex(targetItem, this.numElements - 1);
			_dropIndicator.visible = true;
			_dropPoints = new Point(targetItem.x, targetItem.y);
			_dropIndicator.x = targetItem.x;
			_dropIndicator.y = targetItem.y;

			var lowerLeftX:Number = _draggedItem.x + _draggedItem.width;
			var lowerLeftY:Number = _draggedItem.y + _draggedItem.height;

			// Upper left corner of 14x14 hit area
			var upperLeftX:Number = lowerLeftX - RESIZE_HANDLE_SIZE;
			var upperLeftY:Number = lowerLeftY - RESIZE_HANDLE_SIZE;

			// Mouse positio in Canvas
			var panelRelX:Number = event.localX + _draggedItem.x;
			var panelRelY:Number = event.localY + _draggedItem.y;

			// See if the mousedown is in the resize handle portion of the panel.
			if (upperLeftX <= panelRelX && panelRelX <= lowerLeftX)
			{
				if (upperLeftY <= panelRelY && panelRelY <= lowerLeftY)
				{
					event.stopPropagation();
					_resizing = true;
					startResize(event.stageX, event.stageY);
				}
				else
				{
					_draggedItem.startDrag();
					targetItem.addEventListener(MouseEvent.MOUSE_MOVE, node_mouseMoveHandler, false, 0, true);
				}
			}
			else
			{
				_draggedItem.startDrag();
				targetItem.addEventListener(MouseEvent.MOUSE_MOVE, node_mouseMoveHandler, false, 0, true);
			}
		}

		private function node_mouseMoveHandler(event:MouseEvent):void
		{
			if (_resizing)
				return;
			var indicatorPoint:Point = calculateDropLocation(event);
			if (_dropPoints.x != indicatorPoint.x || _dropPoints.y != indicatorPoint.y)
			{
				_dropIndicator.x = indicatorPoint.x;
				_dropIndicator.y = indicatorPoint.y;
				_dropPoints = indicatorPoint;
				var isHit:Boolean = checkCollision(_dropIndicator);
				if (isHit)
					fixCollision(_dropIndicator);
				updateNodes();
				playNodes();
			}
		}

		private function playNodes():void
		{
			_animations = [];

			var len:Number = _items.length;

			for (var i:int = 0; i < len; i++)
			{
				var pod:BorderContainer = BorderContainer(_pods[i]);
				var item:BorderContainer = BorderContainer(_items[i]);
				if (pod == _draggedItem)
					continue;
				if (pod.x != item.x || pod.y != item.y)
				{
					var move:Move = new Move(pod);
					move.xTo = item.x;
					move.yTo = item.y;
					_animations.push(move);
				}
			}
			if (!_parallel.isPlaying)
				_parallel.end();
			_parallel.duration = 260;
			_parallel.children = _animations;
			_parallel.play();
		}

		private function fixCollision(pod:BorderContainer):void
		{
			var isHit:Boolean;
			var len:Number = _items.length;
			for (var i:int = 0; i < len; i++)
			{
				var currElement:BorderContainer = _items[i] as BorderContainer;
				if (currElement == pod || currElement == _dropIndicator)
					continue;
				isHit = checkOverlap(pod, currElement);
				if (isHit)
				{
					while (currElement.y != (pod.y + pod.height + _verticalGap))
					{
						currElement.y = currElement.y + (_nodeMinHeight + _verticalGap);//pod.y + pod.height + 10; //currElement.y + Math.min(pod.height, _draggedItem.height) + 20;
						fixCollision(currElement);
					}
					trace(currElement.y);
					fixCollision(currElement);
				}
			}
		}

		private function updateNodes():void
		{
			var len:Number = _items.length;
			for (var i:int = 0; i < len; i++)
			{
				var currElement:BorderContainer = _items[i] as BorderContainer;
				if (updateNodeYPos(currElement))
					updateNodes();
			}
		}

		private function updateNodeYPos(node:BorderContainer):Boolean
		{
			var isNodeUpdated:Boolean;
			var oldY:int = node.y;
			node.y = node.y - (_nodeMinHeight + _verticalGap);
			if (node.y >= 0 && checkCollision(node))
			{
				node.y = oldY;
			}
			else if (node.y >= 0)
			{
				isNodeUpdated = true;
				updateNodeYPos(node);
			}
			else
			{
				node.y = oldY;
			}
			return isNodeUpdated;
		}

		private function checkCollision(pod:BorderContainer):Boolean
		{
			var isHit:Boolean;
			var len:Number = _items.length;
			for (var i:int = 0; i < len; i++)
			{
				var currElement:BorderContainer = _items[i] as BorderContainer;
				if (currElement == pod)
					continue;
				isHit = checkOverlap(pod, currElement);
				if (isHit)
					break;
			}
			return isHit;
		}

		private function checkOverlap(A:UIComponent, B:UIComponent):Boolean
		{
			var xOverlap:Boolean = valueInRange(A.x, B.x, B.x + B.width) ||
			                       valueInRange(B.x, A.x, A.x + A.width);

			var yOverlap:Boolean = valueInRange(A.y, B.y, B.y + B.height) ||
			                       valueInRange(B.y, A.y, A.y + A.height);

			return xOverlap && yOverlap;
		}

		private function valueInRange(value:int, min:int, max:int):Boolean
		{
			return (value >= min) && (value <= max);
		}

		private function getDropIndicator(b:BorderContainer):BorderContainer
		{
			var container:BorderContainer = new BorderContainer();
			container.backgroundFill = new SolidColor(_dropIndicatorColor);
			container.setStyle("borderVisible", false);
			container.height = b.height;
			container.width = b.width;
			container.alpha = _dropIndicatorAlpha;
			return container;
		}

		private function calculateDropLocation(event:MouseEvent):Point
		{
			var dropX:int;
			var dropY:int;
			var draggedItem:BorderContainer = event.currentTarget as BorderContainer;
			dropX = draggedItem.x + (draggedItem.width / ((draggedItem.width / (_nodeMinWidth + _horizontalGap)) + 1));
			dropY = draggedItem.y + (draggedItem.height / ((draggedItem.height / (_nodeMinHeight + _verticalGap)) + 1));
			var dropCol:int = dropX / (_nodeMinWidth + _horizontalGap);
			var dropRow:int = dropY / (_nodeMinHeight + _verticalGap);
			var newX:int = dropCol * (_nodeMinWidth + _horizontalGap);
			var newY:int = dropRow * (_nodeMinHeight + _verticalGap);

			return new Point(newX, newY);
		}


		private function sortItems(direction:int):void
		{
			var len:Number = _items.length;
			for (var i:int = 0; i < len; i++)
			{
				for (var j:int = i + 1; j < len; j++)
				{
					var tamp:BorderContainer;
					var value1:Number = _items[j].x + _items[j].y;
					var value2:Number = _items[i].x + _items[i].y;
					if (direction == 1 && value1 < value2)
					{
						tamp = _items[j];
						_items[j] = _items[i];
						_items[i] = tamp;

						tamp = _pods[j];
						_pods[j] = _pods[i];
						_pods[i] = tamp;

					}
					else if (direction == -1 && value1 > value2)
					{
						tamp = _items[j];
						_items[j] = _items[i];
						_items[i] = tamp;

						tamp = _pods[j];
						_pods[j] = _pods[i];
						_pods[i] = tamp;

					}
					else
					{
						tamp = _items[j];
						_items[j] = _items[i];
						_items[i] = tamp;

						tamp = _pods[j];
						_pods[j] = _pods[i];
						_pods[i] = tamp;

					}
				}
			}
		}

		private function node_mouseUpHandler(event:MouseEvent):void
		{
			event.currentTarget.removeEventListener(MouseEvent.MOUSE_MOVE, node_mouseMoveHandler, false);
			if (_parallel.isPlaying)
				_parallel.end();
			_draggedItem.stopDrag();
			_draggedItem.x = _dropIndicator.x;
			_draggedItem.y = _dropIndicator.y;
			_dropIndicator.visible = false;
		}

		private function node_rollOverHandler(event:MouseEvent):void
		{
			(event.currentTarget as BorderContainer).getElementAt(1).visible = true;
		}

		private function node_rollOutHandler(event:MouseEvent):void
		{
			(event.currentTarget as BorderContainer).getElementAt(1).visible = false;
		}


		//******RESIZE HANDLE********//

		private const RESIZE_HANDLE_SIZE:int = 14;
		private var _resizable:Boolean;
		private var resizeInitX:Number = 0;
		private var resizeInitY:Number = 0;
		private var _resizing:Boolean;


		protected function startResize(globalX:Number, globalY:Number):void
		{
			resizeInitX = globalX;
			resizeInitY = globalY;

			// Add event handlers so that the SystemManager handles the mouseMove and mouseUp events.
			// Set useCapure flag to true to handle these events
			// during the capture phase so no other component tries to handle them.
			systemManager.addEventListener(MouseEvent.MOUSE_MOVE, resizeMouseMoveHandler, true);
			trace("startRize");
			systemManager.addEventListener(MouseEvent.MOUSE_UP, resizeMouseUpHandler, true);
		}

		// Resizes this panel as the user moves the cursor with the mouse key down.
		protected function resizeMouseMoveHandler(event:MouseEvent):void
		{
			event.stopImmediatePropagation();

			var newWidth:Number = _draggedItem.width + event.stageX - resizeInitX;
			var newHeight:Number = _draggedItem.height + event.stageY - resizeInitY;

			// restrict the width/height
			if ((newWidth >= minWidth) && (newWidth <= maxWidth))
			{
				_draggedItem.width = newWidth;
			}
			if ((newHeight >= minHeight) && (newHeight <= maxHeight))
			{
				_draggedItem.height = newHeight;
			}

			var closestWidth:Number = getClosestNumber(newWidth, _nodeMinWidth, _horizontalGap);
			var closestHeight:Number = getClosestNumber(newHeight, _nodeMinHeight, _verticalGap);
			var resizeArr:Array = [];
			if (closestWidth != _dropIndicator.width)
			{
				_dropIndicator.width = closestWidth;
				fixCollision(_dropIndicator);
				updateNodes();
				_draggedItem.x = _dropIndicator.x;
				_draggedItem.y = _dropIndicator.y;
				playNodes();
			}
			if (closestHeight != _dropIndicator.height)
			{
				_dropIndicator.height = closestHeight;
				fixCollision(_dropIndicator);
				updateNodes();
				_draggedItem.x = _dropIndicator.x;
				_draggedItem.y = _dropIndicator.y;
				playNodes();
			}
			resizeInitX = event.stageX;
			resizeInitY = event.stageY;
			trace(resizeInitY);
		}

		// Removes the event handlers from the SystemManager.
		protected function resizeMouseUpHandler(event:MouseEvent):void
		{
			_resizing = false;
			event.stopImmediatePropagation();
			systemManager.removeEventListener(MouseEvent.MOUSE_MOVE, resizeMouseMoveHandler, true);
			systemManager.removeEventListener(MouseEvent.MOUSE_UP, resizeMouseUpHandler, true);
			_draggedItem.height = _dropIndicator.height;
			_draggedItem.width = _dropIndicator.width;
			_dropIndicator.visible = false;
		}

		private function getClosestNumber(val:Number, unitNumber:Number, gap:Number):Number
		{
			var value:Number = val - (gap * Math.floor(val / unitNumber));
			var closestNumber:Number;
			var reminder:int = Math.floor(value / unitNumber);

			var smallNumber:Number = reminder * unitNumber;

			var largeNumber:Number = (reminder + 1) * unitNumber;

			var diffWithSmallNum:Number = value - smallNumber;

			var diffWithLargeNum:Number = largeNumber - value;

			if (diffWithSmallNum < diffWithLargeNum)
				closestNumber = smallNumber;
			else
				closestNumber = largeNumber;

			return largeNumber + (gap * reminder);
		}

	}
}
