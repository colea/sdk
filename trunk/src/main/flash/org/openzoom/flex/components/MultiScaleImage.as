////////////////////////////////////////////////////////////////////////////////
//
//  OpenZoom
//
//  Copyright (c) 2007–2008, Daniel Gasienica <daniel@gasienica.ch>
//
//  OpenZoom is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  OpenZoom is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with OpenZoom. If not, see <http://www.gnu.org/licenses/>.
//
////////////////////////////////////////////////////////////////////////////////
package org.openzoom.flex.components
{

import flash.events.Event;
import flash.net.URLLoader;
import flash.net.URLRequest;

import mx.core.UIComponent;

import org.openzoom.flash.descriptors.IMultiScaleImageDescriptor;
import org.openzoom.flash.descriptors.MultiScaleImageDescriptorFactory;
import org.openzoom.flash.net.LoadingQueue;
import org.openzoom.flash.renderers.MultiScaleImageRenderer;
import org.openzoom.flash.viewport.INormalizedViewport;
import org.openzoom.flash.viewport.IViewportConstraint;
import org.openzoom.flash.viewport.IViewportTransformer;
import org.openzoom.flash.viewport.controllers.KeyboardController;
import org.openzoom.flash.viewport.controllers.MouseController;

/**
 * Component for displaying a single multi-scale image. Inspired by the Microsoft
 * Silverlight Deep Zoom MultiScaleImage component. This implementation has built-in
 * support for Zoomify, Deep Zoom and OpenZoom images. Basic keyboard and mouse navigation
 * is included: &laquo;Batteries included&raquo; so to speak.
 */
public class MultiScaleImage extends UIComponent
{   
    //--------------------------------------------------------------------------
    //
    //  Class constants
    //
    //--------------------------------------------------------------------------
   
    private static const DEFAULT_MIN_ZOOM        : Number = 0.25
    private static const DEFAULT_MAX_ZOOM        : Number = 10000
    
    private static const DEFAULT_SCENE_DIMENSION : Number = 12000
    
    private static const DEFAULT_VIEWPORT_WIDTH  : Number = 800
    private static const DEFAULT_VIEWPORT_HEIGHT : Number = 600
    
	//--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     * Constructor.
     */
	public function MultiScaleImage()
	{
	}
	
	//--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------
    
    private var sourceURL : String
    private var sourceLoader : URLLoader
    
    private var image : MultiScaleImageRenderer
    private var container : MultiScaleContainer
    
	//--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------
    
    //----------------------------------
    //  source
    //----------------------------------
    
    private var _source : IMultiScaleImageDescriptor
    
    [Bindable(event="sourceChanged")]
    
    /**
     * Source of this image. Either a URL as String or a IMultiScaleImageDescriptor.
     */ 
    public function get source() : Object
    {
    	return _source
    }
    
    public function set source( value : Object ) : void
    {    	
    	if( _source )
    	{
    		_source = null
	        container.removeChildAt( 0 )
	        viewport.showAll()
    	}
    	
    	if( value is String )
    	{
    		if( sourceURL == String( value ))
                return
    		  
    		sourceURL = String( value )
    		sourceLoader = new URLLoader( new URLRequest( sourceURL ))
    		sourceLoader.addEventListener( Event.COMPLETE, sourceLoader_completeHandler )
    	}
    	
    	if( value is IMultiScaleImageDescriptor )
    	{
            _source = IMultiScaleImageDescriptor( value )
            dispatchEvent( new Event( "sourceChanged" ))
            
            addImage( _source )
    	}
    }
    
    //--------------------------------------------------------------------------
    //
    //  Properties: Scene
    //
    //--------------------------------------------------------------------------
    
    //----------------------------------
    //  sceneWidth
    //----------------------------------
    
    /**
     * @copy org.openzoom.flash.scene.IMultiScaleScene#sceneWidth
     */ 
    public function get sceneWidth() : Number
    {
        return container.scene.sceneWidth
    }
    
    //----------------------------------
    //  sceneHeight
    //----------------------------------
    
    /**
     * @copy org.openzoom.flash.scene.IMultiScaleScene#sceneHeight
     */ 
    public function get sceneHeight() : Number
    {
        return container.scene.sceneHeight
    }
    
    //--------------------------------------------------------------------------
    //
    //  Properties: Viewport
    //
    //--------------------------------------------------------------------------
    
    //----------------------------------
    //  viewport
    //----------------------------------
    
    [Bindable(event="viewportChanged")]
    public function get viewport() : INormalizedViewport
    {
        return container.viewport
    }
    
    //----------------------------------
    //  constraint
    //----------------------------------
    
    public function get constraint() : IViewportConstraint
    {
        return container.viewport.transformer.constraint
    }
    
    public function set constraint( value : IViewportConstraint ) : void
    {
        container.viewport.transformer.constraint = value
    }
    
    //----------------------------------
    //  transformer
    //----------------------------------
    
    public function get transformer() : IViewportTransformer
    {
        return container.viewport.transformer
    }
    
    public function set transformer( value : IViewportTransformer ) : void
    {
        container.viewport.transformer = value
    }
    
	//--------------------------------------------------------------------------
    //
    //  Overridden methods: UIComponent
    //
    //--------------------------------------------------------------------------
    
    override protected function createChildren() : void
    {
    	super.createChildren()
    	
        createContainer()        
        createDefaultControllers()
    }
    
    override protected function updateDisplayList( unscaledWidth : Number,
                                                   unscaledHeight : Number ) : void
    {
        container.width  = unscaledWidth
        container.height = unscaledHeight
    }
    
	//--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------
    
    /**
     * @private
     */
    private function createContainer() : void
    {
    	container = new MultiScaleContainer()
    	addChild( container )
    	
    	dispatchEvent( new Event( "viewportChanged" ))
    }
    
    /**
     * @private
     */
    private function createImage( descriptor : IMultiScaleImageDescriptor,
                                  loader : LoadingQueue,
                                  width : Number, height : Number ) : MultiScaleImageRenderer
    {
        var image : MultiScaleImageRenderer =
                        new MultiScaleImageRenderer( descriptor, loader, width, height )
        image.viewport = viewport
        return image
    }
    
    //--------------------------------------------------------------------------
    //
    //  Methods: Controllers
    //
    //--------------------------------------------------------------------------
    
    /**
     * @private
     */
    private function createDefaultControllers() : void
    {
    	container.controllers = [ new MouseController(),
    	                          new KeyboardController() ]
    }
    
    /**
     * @private
     */
    private function addImage( descriptor : IMultiScaleImageDescriptor ) : void
    {
        var aspectRatio : Number = descriptor.width / descriptor.height 
        var sceneWidth : Number
        var sceneHeight : Number
        
        if( aspectRatio > 1 )
        {
            sceneWidth = DEFAULT_SCENE_DIMENSION
            sceneHeight = DEFAULT_SCENE_DIMENSION / aspectRatio
        }
        else
        {
            sceneWidth = DEFAULT_SCENE_DIMENSION * aspectRatio
            sceneHeight = DEFAULT_SCENE_DIMENSION
        }
        
        // resize scene
        container.sceneWidth  = sceneWidth
        container.sceneHeight = sceneHeight
        
        // create renderer
        image = createImage( descriptor, container.loader, sceneWidth, sceneHeight )
        container.addChild( image )
    }
    
	//--------------------------------------------------------------------------
    //
    //  Event handlers
    //
    //--------------------------------------------------------------------------
    
    /**
     * @private
     */
    private function sourceLoader_completeHandler( event : Event ) : void
    {
    	if( !sourceLoader.data )
    	   return
    	
        var data : XML = new XML( sourceLoader.data )
        var factory : MultiScaleImageDescriptorFactory =
                        MultiScaleImageDescriptorFactory.getInstance()
        var descriptor : IMultiScaleImageDescriptor = factory.getDescriptor( sourceURL, data )
        
        _source = descriptor
        dispatchEvent( new Event( "sourceChanged" ))
        
        addImage( descriptor )
    }
}

}