package selectLetterBar {
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Shape;
import flash.events.MouseEvent;
import flash.geom.Matrix;
import flash.text.AntiAliasType;
import flash.text.TextField;
import flash.text.TextFormat;

import flashx.textLayout.formats.TextAlign;

import mx.core.UIComponent;
import mx.events.ItemClickEvent;

[Event(name="itemClick", type="mx.events.ItemClickEvent")]
public class SelectLetterBar extends UIComponent {
    protected var _letter : TextField;
    protected var _bitmap : Bitmap;
    protected var _styleChanged : Boolean;
    protected var _spacing : Number = 0;
    protected var _letterHeight : Number = 0;
    protected var _currentIndex : int = -1;
    public static const LETTERS : Array = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L",
        "M", "N"];
    private static const PADDING_VERT : Number = 15;
    private var bgRect : Shape;

    public function SelectLetterBar()
    {
        addEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown);
        addEventListener(MouseEvent.MOUSE_UP, handleMouseUp);

        addEventListener(MouseEvent.ROLL_OUT, handleRollOut);
        addEventListener(MouseEvent.ROLL_OVER, handleRollOver);
        width = 51;
    }

    override public function styleChanged(styleProp : String) : void
    {
        super.styleChanged(styleProp);
        _styleChanged = true;
    }

    override protected function createChildren() : void
    {
        super.createChildren();
        bgRect = new Shape();
        addChild(bgRect);
        bgRect.visible = false;

        _letter = new TextField();
        _letter.antiAliasType = AntiAliasType.ADVANCED;
        _bitmap = new Bitmap();
        _bitmap.smoothing = true;
        addChild(_bitmap);
    }

    override protected function commitProperties() : void
    {
        super.commitProperties();
        if (_styleChanged)
        {
            _styleChanged = false;

            var tf : TextFormat = new TextFormat("Arial");
            tf.color = 0xF2F2F2;
            tf.size = 22;
            tf.bold = true;
            tf.align = TextAlign.CENTER;
            _letter.defaultTextFormat = tf;

            invalidateDisplayList();
        }
    }

    override protected function updateDisplayList(unscaledWidth : Number, unscaledHeight : Number) : void
    {
        super.updateDisplayList(unscaledWidth, unscaledHeight);
        if (unscaledWidth == 0 || unscaledHeight == 0)
        {
            return;
        }
        var bd : BitmapData = new BitmapData(unscaledWidth, unscaledHeight, true, 16776960);
        _letter.width = unscaledWidth;
        _letter.text = "W";
        _letterHeight = _letter.getLineMetrics(0).height;
        _spacing = (unscaledHeight - 2 * PADDING_VERT - LETTERS.length * _letterHeight) / (LETTERS.length - 1);
        var ma : Matrix = new Matrix();
        ma.ty = PADDING_VERT;
        for (var i : int = 0; i < LETTERS.length; i++)
        {
            _letter.text = LETTERS[i];
            bd.draw(_letter, ma);
            ma.ty = ma.ty + _letterHeight + _spacing;
        }
        _bitmap.bitmapData = bd;

        bgRect.graphics.clear();
        bgRect.graphics.beginFill(0xEFEFEF, 0.2);
        bgRect.graphics.drawRoundRect(7, 7, unscaledWidth - 14, unscaledHeight - 14, 7, 7);
    }

    protected function handleMouseDown(e : MouseEvent) : void
    {
        removeEventListener(MouseEvent.MOUSE_MOVE, updateCurrentIndex);
        addEventListener(MouseEvent.MOUSE_MOVE, updateCurrentIndex);
        updateCurrentIndex(e);
        bgRect.visible = true;
    }

    protected function handleRollOut(event : MouseEvent) : void
    {
        bgRect.visible = false;
    }

    protected function handleRollOver(event : MouseEvent) : void
    {
        bgRect.visible = true;
    }

    protected function handleMouseUp(event : MouseEvent) : void
    {
        removeEventListener(MouseEvent.MOUSE_MOVE, updateCurrentIndex);
        bgRect.visible = false;
    }

    protected function updateCurrentIndex(event : MouseEvent) : void
    {
        var vertSpacing : Number = PADDING_VERT - _spacing / 2;
        var letterHeightWithSpacing : Number = _letterHeight + _spacing;
        var index : Number = Math.floor((event.localY - vertSpacing) / letterHeightWithSpacing);
        index = Math.min(Math.max(0, index), (LETTERS.length - 1));
        if (index == _currentIndex)
        {
            return;
        }
        dispatchEvent(new ItemClickEvent(ItemClickEvent.ITEM_CLICK, false, false, LETTERS[index], index));
        _currentIndex = index;
    }

}
}
