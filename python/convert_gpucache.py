from maya import cmds
import pymel.core as pm


def apply_material(node):
    """

    Args:
        node: node to get lambert shader

    Returns:
        node with shader and shader group matching its name
    """
    if cmds.objExists(node):
        shd = cmds.shadingNode('lambert', name="%s_lambert" % node, asShader=True)
        shd_sg = cmds.sets(name='%sSG' % shd, empty=True, renderable=True, noSurfaceShader=True)
        cmds.connectAttr('%s.outColor' % shd, '%s.surfaceShader' % shd_sg)
        cmds.sets(node, e=True, forceElement=shd_sg)


def try_get_node(name="", call=True):
    """

    Args:
        name: incoming node
        call: debug call

    Returns:
        Node as Pynode

    """
    try:
        node = pm.PyNode(name)
        return node
    except pm.MayaNodeError as e:
        if call:
            print(e)
        return False


def import_proxy(proxy_node, asset_name):
    """

    Args:
        proxy_node: selected node
        asset_name: base name of node

    Returns:
        an imported geo proxy of the selected cache with a general lambert applied to it.

    """
    gpu_cache_shape = proxy_node
    gpu_cache_shape = try_get_node(gpu_cache_shape, call=False)
    filepath = cmds.getAttr(gpu_cache_shape + '.cacheFileName')
    imported_top = "{}_GeoProxy".format(asset_name)
    imported = cmds.file(filepath, i=1, ra=1, rdn=1, rnn=1)

    try:
        result = cmds.polyUnite(imported, n=imported_top)[0]
        for imp in imported:
            if try_get_node(imp, call=False):
                cmds.delete(imp)

    except:
        for imp in imported:
            if try_get_node(imp).type() == "transform":
                result = pm.rename(imp, imported_top, ignoreShape=False)
                result = result.name()
                break

    imported_top = result

    apply_material(imported_top)

    return imported_top


def convert_cache():
    """

    Returns:
        a geo proxy for every selected cache while hiding the original cache file

    """
    proxies = cmds.ls(sl=True, l=True)

    proxy_count = 0

    for prx in proxies:
        if ":proxy|" in prx:
            print(prx)
            asset_name = prx.split(":")[-1]
            print(asset_name)
            proxy = import_proxy(prx, asset_name)
            cmds.matchTransform(proxy, prx)
            cmds.hide(prx)
            proxy_count += 1

    print("Imported {} proxies".format(proxy_count))
