package com.siloon.containers.table.utils
{
	import com.siloon.containers.table.Cell;
	import com.siloon.containers.table.constant.CellConst;
	import com.siloon.containers.table.table_internal;
	
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	
	import mx.containers.TitleWindow;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.NumericStepper;
	import mx.core.Application;
	import mx.core.mx_internal;
	import mx.events.CloseEvent;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
			
	use namespace mx_internal;			
	use namespace table_internal;
	
	public class SplitCellDialog extends TitleWindow
	{		
		private static var spannedRows:Array;
		private static var dialog:SplitCellDialogView;
		
		public static function open(targetCell:Cell,splitMethod:Function):void
		{
			if(!dialog)
			{
				dialog = new SplitCellDialogView();
			}

			PopUpManager.addPopUp(dialog,DisplayObject(Application.application),true);
			PopUpManager.centerPopUp(dialog);		
							
			dialog.targetCell = targetCell;
			dialog.splitMethod = splitMethod;
			
			dialog.colNum.value = Math.floor(targetCell.width / CellConst.MIN_WIDTH);
			dialog.colNum.minimum = 1;
			dialog.colNum.maximum = Math.floor(targetCell.width / CellConst.MIN_WIDTH);
			
			dialog.rowNum.value = 1;
			dialog.rowNum.minimum = 1;

			spannedRows = targetCell.rows;			
			
			dialog.rowNum.maximum = spannedRows.length == 1?int(targetCell.height / CellConst.MIN_HEIGHT) * 15:spannedRows.length;
		}		
		
		/* controls */
		public var colNum:NumericStepper;		
		public var rowNum:NumericStepper;
		
		private var splitMethod:Function;		
		
		[Bindable]
		public var targetCell:Cell;					
		private var _submultiples:Array;
		
		private function get submultiples():Array 
		{
			_submultiples = null;
			_submultiples = new Array();
			for(var i:Number = rowNum.minimum;i <= rowNum.maximum ; i++)
			{
				if(rowNum.maximum % i == 0)
				{
					_submultiples.push(i);
				}
			}
			return _submultiples;
		}
		
		private function get isValidRowNum():Boolean
		{
			if(spannedRows.length == 1)
			{
				return true;
			}
			if(submultiples.indexOf(rowNum.value) != -1 && spannedRows.length != 1)
			{
				return true;
			}
			else
			{
				Alert.show("Row number must be the submultiple of "+rowNum.maximum);
			}
			return false;
		}
		
		private function get isValidColNum():Boolean
		{
			return true;
		}
	
		public function closeHandler(event:Event):void
		{
			PopUpManager.removePopUp(dialog);
		}
		
		public function rowNumClickHandler(event:MouseEvent):void
		{
			var index:int = submultiples.indexOf(rowNum.value);
			if(event.target == rowNum.prevButton)
			{ 
				if(spannedRows.length == 1)
				{
					rowNum.value = rowNum.value - rowNum.stepSize;
				}
				else if(spannedRows.length > 1)
				{
					rowNum.value = index == 0?rowNum.value:submultiples[index-1];
				}
			}
			if(event.target == rowNum.nextButton)
			{
				if(spannedRows.length == 1)
				{
					rowNum.value = rowNum.value + rowNum.stepSize;
				}
				else if(spannedRows.length > 1)
				{
					rowNum.value = index == submultiples.length - 1?rowNum.value:submultiples[index + 1];
				}
			}
		}
		
		public function removeRowNumDefaultButtonHandler():void
		{
			Button(rowNum.prevButton).addEventListener(FlexEvent.BUTTON_DOWN,buttonDownHandler,false,1);
			Button(rowNum.nextButton).addEventListener(FlexEvent.BUTTON_DOWN,buttonDownHandler,false,1);
		}
		
		public function buttonDownHandler(event:FlexEvent):void
		{
			event.preventDefault();
			event.stopImmediatePropagation();
			event.stopPropagation();
		}
		
		public function confirm():void
		{
			if(isValidRowNum && isValidColNum)
			{
				splitMethod.call(null,targetCell,rowNum.value,colNum.value);
				dispatchEvent(new CloseEvent(CloseEvent.CLOSE));
			}				
		}
		
		public function cancel():void
		{
			dispatchEvent(new CloseEvent(CloseEvent.CLOSE));
		}		
	}
}