import publisher.api
import os
import shutil
import cv2
import maya.cmds as cmds
from library.studio_projects import Studio_LibraryProjects


@publisher.api.log
class FormatCreateLODTextures(publisher.api.InstancePlugin):
    """Create LOD Texture Maps from base Maps"""

    order = publisher.api.FormatOrder - 0.050

    label = 'create LOD textures'
    optional = False
    active = True
    
    def process(self, instance):
        asset_type = instance.data['asset_type']

        if asset_type == 'dress':

            # Constants
            filepath = cmds.file(q=True, sn=True)
            filename = os.path.basename(filepath)
            asset_name = filename.split("_")[0]
            project = Studio_LibraryProjects().get_project(os.getenvironment('PROJECT_CODE'))
            asset_category = project.get_asset_type('dress')
            asset_dir = asset_category.get_path()
            map_dir = os.path.join(asset_dir, asset_name, "maps")
            file_path_med = os.path.join(map_dir, "MED")
            file_path_low = os.path.join(map_dir, "LOW")
            file_path_temp = os.path.join(map_dir, "_TEMP")
            bad_paths = []
            texture_filepath_list = []

            # Get all Textures in Scene
            filelist = cmds.ls(type='file')
            for f in filelist:
                # Get the name of the image attached to it
                texture_filename = cmds.getAttr(f + '.fileTextureName')
                texture_filepath_list.append(texture_filename)

            # Check for incorrectly imported tx files and add to bad_paths list
            for t in texture_filepath_list:
                file_path = os.path.dirname(t)
                correct_dir = map_dir.replace("\\", "/")
                if file_path != correct_dir:
                    if os.path.isdir(file_path):
                        bad_paths.append(t)

            # Make Directories if needed
            if not os.path.exists(file_path_med):
                os.makedirs(file_path_med)
            if not os.path.exists(file_path_low):
                os.makedirs(file_path_low)
            if not os.path.exists(file_path_temp):
                os.makedirs(file_path_temp)

            def resize_textures(tex, fpath, tex_name):
                """

                Args:
                    tex: full filepath to texture
                    fpath: Path for Tex to be saved
                    tex_name: filename of texture image

                Returns:
                    resized textures in both 50% and 25% values

                """
                # Directory to save new Tex File in
                save_file = os.path.join(fpath, tex_name)

                if fpath == file_path_med:
                    div = 2
                else:
                    div = 4

                if not os.path.exists(save_file):
                    img = cv2.imread(tex, cv2.IMREAD_UNCHANGED)
                    vsize = int((float(img.shape[0]) / div))
                    hsize = int((float(img.shape[1]) / div))
                    dim = (vsize, hsize)
                    resized = cv2.resize(img, dim, interpolation=cv2.INTER_LANCZOS4)
                    cv2.imwrite(save_file, resized)

            def convert_textures(folder):
                """

                Args:
                    folder: folder being scraped for textures

                 Returns:
                    resized textures in both 50% and 25% value called through def resize_textures

                """
                tx_dir = os.listdir(folder)

                for m in tx_dir:
                    root, extension = os.path.splitext(m)

                    if extension == ".tx":
                        shutil.copy2(os.path.join(folder, m), file_path_temp)

                        tx = os.path.join(file_path_temp, (root + ".tiff"))

                        tx_file = os.path.join(file_path_temp, m)
                        if os.path.exists(tx_file):
                            tx_rename = os.path.join(file_path_temp, (root + ".tiff"))
                            os.rename(tx_file, tx_rename)

                        tx2_rename = os.path.join(file_path_med, (root + ".tx"))
                        if not os.path.exists(tx2_rename):
                            resize_textures(tx, file_path_med, (root + ".tiff"))

                        tx4_rename = os.path.join(file_path_low, (root + ".tx"))
                        if not os.path.exists(tx4_rename):
                            resize_textures(tx, file_path_low, (root + ".tiff"))

                        txsave_file2 = os.path.join(file_path_med, (root + ".tiff"))
                        if os.path.exists(txsave_file2):
                            os.rename(txsave_file2, tx2_rename)

                        txsave_file4 = os.path.join(file_path_low, (root + ".tiff"))
                        if os.path.exists(txsave_file4):
                            os.rename(txsave_file4, tx4_rename)

                        if os.path.exists(tx_rename):
                            os.remove(tx_rename)

                    else:
                        if extension != "" and extension != ".json" and extension != ".db":
                            shutil.copy2(os.path.join(folder, m), file_path_temp)
                            tx = os.path.join(file_path_temp, m)
                            resize_textures(tx, file_path_med, m)
                            resize_textures(tx, file_path_low, m)
                            del_file = os.path.join(file_path_temp, m)
                            os.remove(del_file)

            convert_textures(map_dir)

            # Delete _TEMP dir after Complete
            if os.path.exists(file_path_temp):
                os.rmdir(file_path_temp)

            # Gives a list of any textures not pathed to the correct directory
            if bad_paths:
                self.log.warning('The following textures have not been ingested correctly:')
                for bp in bad_paths:
                    self.log.warning(bp)
