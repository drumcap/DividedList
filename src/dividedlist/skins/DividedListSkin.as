package dividedlist.skins {
import dividedlist.*;


import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.Event;

import mx.states.State;

import spark.components.DataGroup;
import spark.components.Scroller;
import spark.layouts.HorizontalAlign;
import spark.layouts.VerticalLayout;
import spark.skins.mobile.supportClasses.MobileSkin;

public class DividedListSkin extends MobileSkin {

    public var header : DisplayObject;
    private var _mask : Sprite;
    public var hostComponent : DividedList;
    public var dataGroup : DataGroup;
    public var scroller : Scroller;

    public function DividedListSkin()
    {
        states = [new State({name: "normal"}), new State({name: "disabled"})];
    }

    override protected function createChildren() : void
    {
        super.createChildren();
        var vLayout : VerticalLayout = new VerticalLayout();
        vLayout.requestedMinRowCount = 5;
        vLayout.horizontalAlign = HorizontalAlign.JUSTIFY;
        vLayout.gap = 0;

        dataGroup = new DataGroup();
        dataGroup.layout = vLayout;
        scroller = new Scroller();
        scroller.viewport = dataGroup;
        addChild(scroller);
        createHeader();
        hostComponent.addEventListener("rendererChanged", handleRendererChanged);
    }

    override protected function updateDisplayList(unscaledWidth : Number, unscaledHeight : Number) : void
    {
        super.updateDisplayList(unscaledWidth, unscaledHeight);
        scroller.width = unscaledWidth;
        scroller.height = unscaledHeight;

        if (header)
        {
            var scrollbarWidth : Number = getStyle("isDesktop") ? hostComponent.scroller.verticalScrollBar.width : 0;
            //header.setActualSize(unscaledWidth - scrollbarWidth, header.measuredHeight);
            header.width = unscaledWidth - scrollbarWidth;
            _mask.width = unscaledWidth - scrollbarWidth;
            _mask.height = unscaledHeight;
        }

    }

    protected function createHeader() : void
    {
        if (!hostComponent.itemRenderer)
        {
            return;
        }
        header = hostComponent.itemRenderer.newInstance();
        addChild(header);
        if (!_mask)
        {
            _mask = new Sprite();
            _mask.graphics.beginFill(16711680, 0.4);
            _mask.graphics.drawRect(0, 0, 100, 100);
            addChild(_mask);
        }
        header.mask = _mask;
    }

    protected function destroyHeader() : void
    {
        if (!header)
        {
            return;
        }
        removeChild(header);
        header = null;
    }

    protected function handleRendererChanged(event : Event) : void
    {
        if (header)
        {
            destroyHeader();
        }
        createHeader();
    }

}
}