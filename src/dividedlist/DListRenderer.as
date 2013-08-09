package dividedlist {

import flash.display.GradientType;
import flash.display.SpreadMethod;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Matrix;
import flash.text.TextField;
import flash.text.TextFormat;

import mx.core.IDataRenderer;
import mx.core.UIComponent;

import spark.components.IItemRenderer;

/** minimalistic renderer aiming for max performance */
public class DListRenderer extends UIComponent implements IDataRenderer, IItemRenderer {

    private const DIVIDERHEIGHT : uint = 90;
    private const NORMALHEIGHT : uint = 60;

    private const lText : TextField = new TextField();
    private var _data : ListData;
    protected var myWidth : Number;
    protected var myHeight : Number = NORMALHEIGHT;
    protected var _state : String = "__NONE";
    private var oldHeight : int = -1;
    protected const tf : TextFormat = new TextFormat("arial", 28, 0xc5c5c5, true);

    public function DListRenderer() : void
    {
        opaqueBackground = 0x000000;
        //cacheAsBitmap = true -- this actually causes slowdown. I think, because it gets redrawn quite often.
        percentWidth = 100;
        lText.multiline = true;
        lText.selectable = false;
        lText.mouseEnabled = false;
        lText.wordWrap = true;
        lText.cacheAsBitmap = true; // this causes speedup
        lText.height = 90;
        lText.y = 16;
        lText.x = 30;
        lText.defaultTextFormat = tf;
        addEventListener(MouseEvent.MOUSE_DOWN, onMdown, false, 0, true);
        addEventListener(MouseEvent.ROLL_OUT, onMup, false, 0, true);
        addEventListener(MouseEvent.MOUSE_UP, onMup, false, 0, true);
        addEventListener(MouseEvent.CLICK, onMClick, false, 0, true);
        addEventListener("widthChanged", onWidthChanged, false, 0, true);

        addChild(lText);
        lText.text = "Initializing..";
    }

    private function onWidthChanged(e : Event) : void
    {
        redraw(_state);
    }

    private function onMClick(event : MouseEvent) : void
    {
        if (data && _data.isDivider == false)
        {
            owner.dispatchEvent(new Event("rendererclick"));
        }
    }

    private function onMup(event : MouseEvent) : void
    {
        redraw("up");
    }

    private function onMdown(event : MouseEvent) : void
    {
        redraw("down");
    }

    protected function redraw(mystate : String) : void
    {
        if (mystate == _state && myHeight == oldHeight && myWidth == owner.width)
        {
            return;
        }
        myWidth = owner.width;
        oldHeight = myHeight;
        lText.width = myWidth - 30;
        _state = mystate;
        graphics.clear();
        if (mystate == "up")
        {
            const ma : Matrix = new Matrix();
            ma.createGradientBox(myWidth, myHeight, -0.58, 0, 0);
            graphics.beginGradientFill(GradientType.LINEAR,
                    [0x2D2C2D, 0x231F20, 0x231F20, 0x2D2C2D],
                    [1, 1, 1, 1], [0, 110, 150, 255], ma, SpreadMethod.PAD);
        }
        else if (mystate == "down")
        {
            graphics.beginFill( 0x676767 );
        }
        else
        { // divider state
            graphics.beginFill(0x00AEEF);
        }
        graphics.drawRect(0, 0, myWidth, myHeight);
        graphics.lineStyle(3, 0x414042);
        graphics.moveTo(0, 0);
        graphics.lineTo(myWidth, 0);
        graphics.moveTo(0, myHeight);
        graphics.lineTo(myWidth, myHeight);
    }

    public function set data(d : Object) : void
    {
        _data = d as ListData;
        if (_data == null)
        {
            return;
        }
        lText.text = _data.data.name;
        if (_data.isDivider == true)
        {
            mouseEnabled = mouseChildren = false;
            height = myHeight = DIVIDERHEIGHT;
            lText.y = 6;
            lText.height = 40;
            redraw("divider");
        } else
        {
            mouseEnabled = mouseChildren = true;
            height = myHeight = NORMALHEIGHT;
            lText.height = lText.textHeight + 6;
            lText.y = 16;
            redraw("up");
        }
    }

    override protected function measure() : void
    {
        measuredMinWidth = 0;
        measuredMinHeight = 0;
        measuredWidth = myWidth;
        measuredHeight = myHeight;
    }

    // this stuff is only here to implement interfaces
    public function get data() : Object
    {
        return _data;
    }

    private var _itemIndex : int;
    public function get itemIndex() : int
    {
        return _itemIndex;
    }

    public function set itemIndex(value : int) : void
    {
        _itemIndex = value;
    }

    public function get dragging() : Boolean
    {
        return false;
    }

    public function set dragging(value : Boolean) : void
    {
    }

    public function get label() : String
    {
        return lText.text;
    }

    public function set label(value : String) : void
    {
    }

    public function get selected() : Boolean
    {
        return false;
    }

    public function set selected(value : Boolean) : void
    {
    }

    public function get showsCaret() : Boolean
    {
        return false;
    }

    public function set showsCaret(value : Boolean) : void
    {
    }
}
}