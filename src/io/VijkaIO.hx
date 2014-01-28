package io;

import common.Point;
import format.ett.Reader;
import haxe.io.Eof;
import network.Link;
import network.Network;
import network.Node;
import sys.FileSystem;
import sys.io.File;
import Sys.print;
import Sys.println;

typedef VijkaIOConfig = {
	var nodeFile:String;
	var linkFile:String;
	var linkAliasFile:String;
	var linkShapeFile:String;
}

class VijkaIO {

	public static
	function read( config:VijkaIOConfig ):Network {
		print( "Reading a Vijka Network..." );
		var network = new Network( 0. );
		print( "Reading a Vijka Network... Nodes" );
		readNodes( network, config.nodeFile );
		print( "Reading a Vijka Network... Links" );
		readLinks( network, config.linkFile );
		print( "Reading a Vijka Network... Link shapes" );
		readShapes( network, config.linkShapeFile );
		print( "Reading a Vijka Network... Link aliases" );
		readAliases( network, config.linkAliasFile );
		println( "Reading a Vijka Network... Done!     " );
		return network;
	}

	static
	function readNodes( network:Network, path:String ) {
		var einp = readEtt( path );
		while ( true ) {
			var vijkaNode = try { einp.fastReadRecord( elebeta.ett.vijka.Node.makeEmpty() ); }
			                catch ( e:Eof ) { null; };
			if ( vijkaNode == null ) break;
			var node = makeNode( network, vijkaNode );
			network.nodes.add( node );
		}
		einp.close();
	}

	static
	function makeNode( network, vijkaNode:elebeta.ett.vijka.Node ) {
		return new Node( vijkaNode.id, makePoint( vijkaNode.point ) );
	}

	static
	function makePoint( vijkaPoint ) {
		return new Point( vijkaPoint.x, vijkaPoint.y );
	}

	static
	function readLinks( network:Network, path:String ) {
		var einp = readEtt( path );
		while ( true ) {
			var vijkaLink = try { einp.fastReadRecord( elebeta.ett.vijka.Link.makeEmpty() ); }
			                catch ( e:Eof ) { null; };
			if ( vijkaLink == null ) break;
			var link = makeLink( network, vijkaLink );
			network.links.add( link );
		}
		einp.close();
	}

	static
	function makeLink( network:Network, vijkaLink:elebeta.ett.vijka.Link ) {
		var from = network.nodes.getId( vijkaLink.startNodeId );
		if ( from != null )
			throw 'Missing from node ${vijkaLink.startNodeId} for link ${vijkaLink.id}';
		var to = network.nodes.getId( vijkaLink.finishNodeId );
		if ( to != null )
			throw 'Missing to node ${vijkaLink.finishNodeId} for link ${vijkaLink.id}';
		return new Link( from, to, vijkaLink.id, vijkaLink.extension, vijkaLink.typeId, vijkaLink.toll );
	}

	static
	function readShapes( network:Network, path:String ) {
		var einp = readEtt( path );
		while ( true ) {
			var vijkaShape = try { einp.fastReadRecord( elebeta.ett.vijka.LinkShape.makeEmpty() ); }
			                catch ( e:Eof ) { null; };
			if ( vijkaShape == null ) break;
			var link = network.links.getId( vijkaShape.linkId );
			importShape( link, vijkaShape );
		}
		einp.close();
	}

	static
	function importShape( link:Link, vijkaShape:elebeta.ett.vijka.LinkShape ) {
		link.inflections.clear();
		for ( vp in vijkaShape.shape.array() ) {
			link.inflections.add( makePoint( vp ) );
		}
	}

	static
	function readAliases( network:Network, path:String ) {
		var einp = readEtt( path );
		while ( true ) {
			var vijkaAlias = try { einp.fastReadRecord( elebeta.ett.vijka.LinkAlias.makeEmpty() ); }
			                catch ( e:Eof ) { null; };
			if ( vijkaAlias == null ) break;
			var link = network.links.getId( vijkaAlias.linkId );
			importAlias( link, vijkaAlias );
		}
		einp.close();
	}

	static
	function importAlias( link:Link, vijkaAlias:elebeta.ett.vijka.LinkAlias ) {
		link.aliases.add( vijkaAlias.name );
	}

	static
	function readFile( path:String, binary:Bool ) {
		if ( !FileSystem.exists( path ) )
			throw "File \""+path+"\" does not exist";
		if ( FileSystem.isDirectory( path ) )
			throw "Expected a file but found a folder: \""+path+"\"";
		return File.read( path, binary );
	}

	static
	function readEtt( path:String ) {
		return new ETTReader( readFile( path, true ) );
	}

}