import os
import datetime
from PySide2 import QtCore, QtWidgets
from shiboken2 import wrapInstance
import maya.OpenMayaUI as omui
import pymel.core as pm
from SHOW.xxxxxxxx.utils import xxxx_xxxxxx
import tempfile
import sys
import DeadlineConnect as connect
import subprocess
import requests

reload(xxxx_xxxxxx)

# make sure to use local server to get correct pools and groups
sys.path.append("dir01")
sys.path.append("dir02")

# Determine server location
public_ip = requests.get('https://www.wikipedia.org').headers['X-Client-IP']
if public_ip.startswith(('XX', 'XY')):
    location = 'LOC1'
else:
    location = 'LOC2'
deadline_server = "LOC1-DEADLINE" if location == 'LOC1' else "LOC2-DEADLINE"


class deadline_submitter(object):
    """
    Class to create Deadline submission jobs in Python
    """

    @staticmethod
    def init_Deadline():
        connectionObject = connect.DeadlineCon(deadline_server, ####)
        pools = connectionObject.Pools.GetPoolNames()
        groups = connectionObject.Groups.GetGroupNames()
        deadlineCon = {'pools': pools, 'groups': groups}
        return deadlineCon

    @staticmethod
    def populate_encode_plugininfo_data(scrape_type, asset, srf_version, srf, rga_version, rga, asset_path, scrape_directory):
        """

        Args:
            scrape_type: 0 - Char or Prop, 1 - Sets
            asset: Name of Asset
            srf_version: srf version (Char and Prop only)
            srf: path to srf file (Char and Prop only)
            rga_version: rga version (Char and Prop only)
            rga: path to rga file (Char and Prop only)
            asset_path: path to asset file (Set only)
            scrape_directory: full scrape directory (Set only)

        Returns:
            Populated plugininfo string to be written to txt file

        """

        if scrape_type == 1:
            plgInfo = {
                "ScriptFile": "c:\\dir\\scriptfile.py",
                "Arguments": "c:\\dir\\charpropsubmit.py --asset {} --srf_version {} --srf {} --rga_version {} --rga {}".format(asset, srf_version, srf, rga_version, rga),
                "Version": 2.7,
                "SingleFramesOnly": False
            }
        else:
            plgInfo = {
                "ScriptFile": "c:\\dir\\scriptfile.py",
                "Arguments": "c:\\dir\\setsubmit.py --asset_path {} --scrape_directory {}".format(asset_path, scrape_directory),
                "Version": 2.7,
                "SingleFramesOnly": False
            }

        return plgInfo

    @staticmethod
    def populate_encode_jobinfo_data(batch_name, asset):
        """

        Args:
            batch_name: Name of Batch Job (ex. SHOW_ingestion_2022-06-01_134213)
            asset: name of asset being sent in job

        Returns:
            jobinfo string to be written to txt file

        """

        job_name = "SHOW_{}_ingestion_job".format(asset)

        jobsInfo = {
            "Plugin": "Python_XX",
            "BatchName": batch_name,
            "Comment": "",
            "TaskTimeoutMinutes": 0,
            "LimitGroups": "",
            "Group": "none",
            "Name": job_name,
            "MachineLimit": 0,
            "Whitelist": "",
            "InitialStatus": "Active",
            "EnableAutoTimeout": False,
            "SecondaryPool": "",
            "Priority": 85,
            "LimitConcurrentTasksToNumberOfCpus": True,
            "Department": "",
            "ConcurrentTasks": 1,
            "OnJobComplete": "Nothing",
            "Pool": "VrayPool",
            "Frames": 0,
            "ChunkSize": 1,
            "PreTaskScript": "S:\\deploy\\deployer\\run_deploy_slave.py",
            "EnvironmentKeyValue0": "PROJECT_ROOT = P:\SHOW",
            "EnvironmentKeyValue1": "PROJECT_CODE = SHOW"
        }

        return jobsInfo

    @staticmethod
    def farm_submission(scrape_type, batch_name, asset, srf_version=None, srf=None, rga_version=None, rga=None, asset_path=None, scrape_directory=None):
        """

        Args:
            scrape_type: 0 - Set, 1 - Char/Prop
            batch_name: Name of Batch Job (ex. SHOW_ingestion_2022-06-01_134213)
            asset: name of asset being sent in job
            srf_version: srf version (Char and Prop only)
            srf: path to srf file (Char and Prop only)
            rga_version: rga version (Char and Prop only)
            rga: path to rga file (Char and Prop only)
            asset_path: path to asset file (Set only)
            scrape_directory: full scrape directory (Set only)

        Returns:
            - jobinfo txt file
            - plugininfo txt file
            - deadline submission job(s)

        """

        encode_job_info_dict = deadline_submitter.populate_encode_jobinfo_data(batch_name, asset)
        encode_plugin_info_dict = deadline_submitter.populate_encode_plugininfo_data(scrape_type, asset, srf_version, srf, rga_version, rga, asset_path, scrape_directory)

        # Create deadlinecommand for encode job file and plugin file
        encode_job_info_text = ""
        for p in encode_job_info_dict:
            encode_job_info_text += "{}={}\n".format(p, encode_job_info_dict[p])

        encode_plugin_info_text = ""
        for p in encode_plugin_info_dict:
            encode_plugin_info_text += "{}={}\n".format(p, encode_plugin_info_dict[p])

        encode_job_info_file = tempfile.mkstemp(suffix="_job_info_{}.txt".format(encode_job_info_dict["Plugin"]))
        with open(encode_job_info_file[1], "w") as f:
            f.write(encode_job_info_text)

        encode_plugin_info_file = tempfile.mkstemp(suffix="_plugin_info_{}.txt".format(encode_job_info_dict["Plugin"]))
        with open(encode_plugin_info_file[1], "w") as f:
            f.write(encode_plugin_info_text)

        os.close(encode_job_info_file[0])
        os.close(encode_plugin_info_file[0])

        # deadline cmd submission command
        ddCommand = "C:\\Progra~1\\Thinkbox\\Deadline10\\bin\\deadlinecommand.exe"
        cmdline = ddCommand + " " + "\"" + encode_job_info_file[1] + "\"" + " " + "\"" + encode_plugin_info_file[1] + "\""

        print(cmdline)

        process = subprocess.Popen(cmdline, creationflags=subprocess.SW_HIDE, shell=True, stdout=subprocess.PIPE)
        process_result = process.communicate()[0]

        return True


def maya_main_window():
    """
    Return the Maya main window widget as a Python object
    """

    main_window_ptr = omui.MQtUtil.mainWindow()
    return wrapInstance(long(main_window_ptr), QtWidgets.QWidget)


class IngesterAppDialog(QtWidgets.QDialog):
    """
    Main Ingester Tool Dialog
    """

    wnd_instance = None

    def __init__(self, parent=maya_main_window()):
        super(IngesterAppDialog, self).__init__(parent)

        self.setWindowTitle('Ingester App Dialog')
        self.setMinimumWidth(242)
        self.setMaximumHeight(100)
        self.setWindowFlags(self.windowFlags() ^ QtCore.Qt.WindowContextHelpButtonHint)
        self.ingest_directory = r'P:\SHOW\Client_Deliveries\dir'

        self.asset_dict = None

        self.create_widgets()
        self.create_layouts()
        self.create_connections()

    def create_widgets(self):
        self.dir_btn = QtWidgets.QPushButton('Get Directory')
        self.lineedit = QtWidgets.QLineEdit()
        self.lineedit.setPlaceholderText('Paste Directory Here')

        self.assettype_dd = QtWidgets.QComboBox()
        self.assettype_dd.addItems(['Set', 'Character / Prop'])

        self.ok_btn = QtWidgets.QPushButton('OK')
        self.cancel_btn = QtWidgets.QPushButton('Cancel')

    def create_layouts(self):
        layout_row1 = QtWidgets.QFormLayout()
        layout_row1.addRow(self.dir_btn, self.lineedit)

        layout_row2 = QtWidgets.QFormLayout()
        layout_row2.addRow('Asset Type:', self.assettype_dd)

        layout_row3 = QtWidgets.QHBoxLayout()
        layout_row3.addWidget(self.ok_btn)
        layout_row3.addWidget(self.cancel_btn)

        main_layout = QtWidgets.QVBoxLayout(self)
        main_layout.addLayout(layout_row1)
        main_layout.addLayout(layout_row2)
        main_layout.addLayout(layout_row3)

    def create_connections(self):
        self.dir_btn.clicked.connect(lambda: self.get_dir())
        self.lineedit.editingFinished.connect(lambda: self.set_dir(self.lineedit.text()))
        self.ok_btn.clicked.connect(lambda: self.execute_ingest(self.assettype_dd.currentIndex(), self.lineedit.text()))
        self.assettype_dd.activated.connect(lambda: pm.displayInfo("Asset Ingest Type set to: {}".format(self.assettype_dd.currentText())))
        self.cancel_btn.clicked.connect(self.close)

    def error_box(self, msg):
        """
        Reusable error box
        """

        pm.displayError("{}".format(msg))
        QtWidgets.QMessageBox.critical(self, 'Error', msg)

    def set_dir(self, scrape_dir):
        """

        Args:
            scrape_dir: new asset directory

        Returns:
            If different from existing directory, displays notification in Status bar that directory has been changed.

        """

        if scrape_dir != self.ingest_directory and scrape_dir != "":
            self.ingest_directory = scrape_dir
            pm.displayInfo("Scrape Directory set to: {}".format(self.ingest_directory))

    def get_dir(self):
        """
        uses Windows file manager to choose and return directory rather than pasting into text field
        """

        scrape_dir = QtWidgets.QFileDialog.getExistingDirectory(self, "Browse for directory", self.ingest_directory)
        if scrape_dir:
            self.set_dir(scrape_dir)
            self.lineedit.setText(scrape_dir)

    def execute_ingest(self, asset_type, scrape_directory):
        """

        Args:
            asset_type: Character / Prop or Set, determines which method of ingest
            scrape_directory: directory that will be scraped for assets to ingest

        Returns:
            All the info required to create deadline submissions jobs to be passed to farm_submission()

        """

        if scrape_directory == '':
            self.error_box('No directory specified.')
        else:
            if not os.path.isdir(scrape_directory):
                self.error_box('Scrape Directory is not a valid directory.')
            else:

                # Char/Prop
                if asset_type == 1:
                    self.asset_dict = xxxx_xxxxxx.xxxxxxxxxx(scrape_directory).get_asset_to_pub()
                    print(self.asset_dict)
                    asset_list = []
                    for ad in self.asset_dict:
                        asset_list.append(ad)

                    # Pass list of assets in folder to selection dialog
                    choose_assets = CharPropConfirmDialog(self, asset_list)
                    result = choose_assets.exec_()

                    if result == QtWidgets.QDialog.Accepted:
                        print('Asset Type: Char/Prop')
                        chosen_list = choose_assets.get_assets()
                        if chosen_list:
                            current_time = datetime.datetime.now()
                            batch_name = "SHOW_ingestion_" + datetime.date.isoformat(datetime.date.today()) + "_" + str(
                                current_time.hour) + str(current_time.minute) + str(
                                current_time.second)

                            for ca in chosen_list:
                                asset_name = ca.text()
                                srf_version = self.asset_dict[ca.text()].get("srf_version", None)
                                srf = self.asset_dict[ca.text()].get("srf", None)
                                rga_version = self.asset_dict[ca.text()]["rga_version"]
                                rga = self.asset_dict[ca.text()]["rga"]
                                if not srf:
                                    srf = rga
                                    srf_version = rga_version

                                if rga:
                                    deadline_submitter.farm_submission(1, batch_name, asset_name, srf_version=srf_version, srf=srf, rga_version=rga_version, rga=rga)
                        else:
                            self.error_box('No asset selected.')
                    else:
                        pm.displayInfo('Char/Prop ingestion cancelled.')

                # Set
                elif asset_type == 0:
                    print('Asset Type: Set')

                    sdr_asset_path = []
                    sanm_asset_path = []
                    srnd_asset_path = []

                    # Scrape dir for possible usable Maya files
                    for root, dirs, files in os.walk(scrape_directory):
                        for f in files:
                            if '_sdr_' in f and f.endswith('.ma') and not root.endswith('work'):
                                sdr_asset_path.append(root + "\\" + f)
                            if '_sanm_' in f and f.endswith('.ma') and not root.endswith('work'):
                                sanm_asset_path.append(root + "\\" + f)
                            if '_srnd_' in f and f.endswith('.ma') and not root.endswith('work'):
                                srnd_asset_path.append(root + "\\" + f)

                    if len(sdr_asset_path) == 1:
                        asset_path = sdr_asset_path[0]
                    elif len(sanm_asset_path) == 1:
                        asset_path = sanm_asset_path[0]
                    elif len(srnd_asset_path) == 1:
                        asset_path = srnd_asset_path[0]
                    else:
                        self.error_box('Asset file conditions not met.')
                        asset_path = False

                    # Confirm needed file found and User would like to proceed.
                    if asset_path:
                        asset = os.path.basename(asset_path)
                        asset_name = asset.split(".")[0].split("_")[2]
                        dlg = QtWidgets.QMessageBox(self)
                        dlg.setWindowTitle("Confirm Set Ingestion")
                        dlg.setText('{} set found.\nWould you like to proceed with ingest on this set asset?'.format(asset))
                        dlg.setStandardButtons(QtWidgets.QMessageBox.Yes | QtWidgets.QMessageBox.No)
                        dlg.setIcon(QtWidgets.QMessageBox.Question)
                        button = dlg.exec_()

                        if button == QtWidgets.QMessageBox.Yes:
                            asset_path = asset_path.replace("/", "\\")
                            scrape_directory = scrape_directory.replace("/", "\\")

                            current_time = datetime.datetime.now()
                            batch_name = "SHOW_ingestion_" + datetime.date.isoformat(datetime.date.today()) + "_" + str(current_time.hour) + str(current_time.minute) + str(
                                current_time.second)

                            deadline_submitter.farm_submission(0, batch_name, asset_name, asset_path=asset_path, scrape_directory=scrape_directory)

                        else:
                            pm.displayInfo('{} ingestion cancelled.'.format(os.path.basename(asset_path)))

                # Failsafe
                else:
                    self.error_box('Asset Type Error')

    @classmethod
    def display(cls):
        if not cls.wnd_instance:
            cls.wnd_instance = IngesterAppDialog()

        if cls.wnd_instance.isHidden():
            cls.wnd_instance.show()
        else:
            cls.wnd_instance.raise_()
            cls.wnd_instance.activateWindow()


class CharPropConfirmDialog(QtWidgets.QDialog):
    """
    Dialog Window for Char/Prop that allows user to select which of the props they want to ingest
    """

    def __init__(self, parent, assetlist):
        super(CharPropConfirmDialog, self).__init__(parent)

        self.setWindowTitle('Confirm Char/Prop Ingestion Assets')
        self.setWindowFlags(self.windowFlags() ^ QtCore.Qt.WindowContextHelpButtonHint)

        self.assetlist = assetlist

        self.create_widgets()
        self.create_layout()
        self.create_connections()

    def create_widgets(self):
        self.header = QtWidgets.QLabel('Here are the Char/Prop assets found:')
        self.assetlist_wdg = QtWidgets.QListWidget()
        self.assetlist_wdg.addItems(self.assetlist)
        self.assetlist_wdg.setSelectionMode(QtWidgets.QAbstractItemView.MultiSelection)
        self.assetlist_wdg.selectAll()

        self.ok_btn = QtWidgets.QPushButton("Submit")
        self.cancel_btn = QtWidgets.QPushButton('Cancel')

    def create_layout(self):
        layout_row3 = QtWidgets.QHBoxLayout()
        layout_row3.addWidget(self.ok_btn)
        layout_row3.addWidget(self.cancel_btn)

        main_layout = QtWidgets.QVBoxLayout(self)
        main_layout.addWidget(self.header)
        main_layout.addWidget(self.assetlist_wdg)
        main_layout.addLayout(layout_row3)

    def create_connections(self):
        self.ok_btn.clicked.connect(self.accept)
        self.cancel_btn.clicked.connect(self.close)

    def get_assets(self):
        return self.assetlist_wdg.selectedItems()

def main():
    try:
        ingester_app_dialog.close()
        ingester_app_dialog.deleteLater()
    except:
        pass

    ingester_app_dialog = IngesterAppDialog()
    ingester_app_dialog.show()


if __name__ == "__main__":
    main()
