import subprocess
import os
import sys
import time
import traceback
from xxxxx.utils.text import format_duration, lprint


class Process(object):
    def __init__(self):
        from xxxxx.sapplications._deadline import libDeadline
        self.libdeadline = libDeadline(self)

    def import_data_deadline(self):
        lprint("Getting data from Deadline")
        self.current_job = self.libdeadline['current_job']
        self.job_data = self.current_job['extra_info']['task_data']

        lprint(self.job_data)

    def on_failed(self):
        lprint("Failed script_job")
        os._exit(1)

    def run(self):
        """

        Returns: Deadline submission job

        """
        script_start = time.time()

        try:
            self.import_data_deadline()
            self.execute()

            lprint("Job complete in {}".format(format_duration(time.time() - script_start)))
            os._exit(0)

        except Exception as e:
            traceback.print_exc()
            lprint(e)
            self.on_failed()

    def run_popen(self, cmd):
        """A generator to continually yield the stdout of a running Popen process.

        Duplicate logging messages from pymel are also filtered out.

        Args:
            cmd (list): Command line args to send to the Popen function.

        Yields:
            str: the next line of the stdout from the process.
        """
        license_servers = 'ws-001;ws-002'
        p = subprocess.Popen(cmd, env=os.environ.copy(), stderr=subprocess.STDOUT,
                             stdout=subprocess.PIPE, universal_newlines=True, shell=True)

        for stdout_line in iter(p.stdout.readline, ""):
            if 'OpenGL (GL_INVALID_OPERATION)' in stdout_line:
                sys.exit(1)
            else:
                yield stdout_line
        p.stdout.close()
        return_code = p.wait()
        if return_code:
            raise subprocess.CalledProcessError(return_code, cmd)

    def set_comp(self, matte_dir, c, in_path, frame_start, frame_end):
        """

        Args:
            matte_dir: Directory where mattes are kept
            c: Character
            in_path: Path to first frame
            frame_start: First frame number
            frame_end: Last frame number

        Returns:
            Creates custom comp for char and saves it in its matte folder

        """

        f_name = os.path.basename(in_path)
        # print("Inpath: " + in_path)
        show_repo = os.path.normpath(os.path.join(__file__, '..', '..', '..', '..'))
        matte_comp_dir = os.path.normpath(os.path.join(show_repo, 'dir01', 'dir02', 'dir03', 'dir04'))
        matte_comp_temp = os.path.join(matte_dir, 'CharComp_' + c + '.comp')

        if f_name.startswith("Char01"):
            # print("Switcher is Char01")
            matte_comp = os.path.join(matte_comp_dir, 'CharComp_Char01.comp')

        elif f_name.startswith("Char02"):
            # print("Switcher is Char02")
            if 'Belt' in f_name and 'BeltB' not in f_name:
                matte_comp = os.path.join(matte_comp_dir, 'CharComp_Char02_utilbelt.comp')
            else:
                matte_comp = os.path.join(matte_comp_dir, 'CharComp_Char02.comp')

        elif f_name.startswith("Char03"):
            # print("Switcher is Char03")
            in_path = in_path.replace("mattes", "color")
            matte_comp = os.path.join(matte_comp_dir, 'CharComp_Char03.comp')

        elif f_name.startswith("Char04"):
            # print("Switcher is Char04")
            matte_comp = os.path.join(matte_comp_dir, 'CharComp_Char04.comp')

        elif f_name.startswith("Char05"):
            # print("Switcher is Char05")
            matte_comp = os.path.join(matte_comp_dir, 'CharComp_Char05.comp')

        elif f_name.startswith("Char06"):
            # print("Switcher is Char06")
            matte_comp = os.path.join(matte_comp_dir, 'CharComp_Char06.comp')

        elif f_name.startswith("Char07"):
            # print("Switcher is Char07")
            matte_comp = os.path.join(matte_comp_dir, 'CharComp_Char07.comp')

        elif f_name.startswith("Char08"):
            # print("Switcher is Char08")
            matte_comp = os.path.join(matte_comp_dir, 'CharComp_Char08.comp')

        elif f_name.startswith("Char08var"):
            # print("Switcher is Char08var - Char08")
            matte_comp = os.path.join(matte_comp_dir, 'CharComp_Char08.comp')

        elif f_name.startswith("Char09"):
            # print("Switcher is Char09")
            matte_comp = os.path.join(matte_comp_dir, 'CharComp_Char09.comp')

        elif f_name.startswith("Char10"):
            # print("Switcher is Char10")
            matte_comp = os.path.join(matte_comp_dir, 'CharComp_Char10.comp')

        elif f_name.startswith("Char11"):
            # print("Switcher is Char11")
            matte_comp = os.path.join(matte_comp_dir, 'CharComp_Char11.comp')

        elif f_name.startswith("Char12"):
            # print("Switcher is Char12")
            matte_comp = os.path.join(matte_comp_dir, 'CharComp_Char12.comp')

        elif f_name.startswith("C13"):
            # print("Switcher is Char13")
            if 'Ramp' in f_name:
                matte_comp = os.path.join(matte_comp_dir, 'CharComp_Char13_ramp.comp')
            else:
                matte_comp = os.path.join(matte_comp_dir, 'CharComp_Char13.comp')

        elif f_name.startswith("Char14"):
            # print("Switcher is Char14")
            matte_comp = os.path.join(matte_comp_dir, 'CharComp_Char14.comp')

        file_exists = os.path.exists(matte_comp)

        if file_exists:
            # overwrites temp flags in comps with correct paths for read and save assets
            with open(matte_comp, 'r') as f:
                compfile = f.read()

            in_path = in_path.replace("\\", "\\\\")
            compfile = compfile.replace("_INPUT_FILENAME", in_path)
            matte_name = os.path.basename(in_path)
            path = os.path.normpath(os.path.join(in_path, '..', '..'))
            outpath = os.path.join(path, matte_name)
            outpath = outpath.replace("\\", "\\\\")
            compfile = compfile.replace("_OUTPUT_FILENAME", str(outpath))

            compfile = compfile.replace("_START_FRAME", str(frame_start))
            compfile = compfile.replace("_END_FRAME", str(frame_end))
            length = (int(frame_end) - (int(frame_start) - 1))
            compfile = compfile.replace("_INPUT_LENGTH", str(length))
            compfile = compfile.replace("_TRIM_OUT", str(length-1))
            if f_name.startswith("Char03"):
                pattern = os.path.join(matte_comp_dir, 'alternatepattern.png')
            else:
                pattern = os.path.join(matte_comp_dir, 'mainpattern.png')
            pattern = pattern.replace("\\", "\\\\")
            compfile = compfile.replace("PATTERN", str(pattern))

            with open(matte_comp_temp, 'w') as f:
                f.write(compfile)

        else:
            matte_comp_temp = False

        return matte_comp_temp

    def execute(self):
        """

        Returns: cmd string to send to deadline

        """
        job_key = next(iter(self.job_data['jobs']))
        task_key = next(iter(self.job_data['jobs'][job_key]))

        maya_file = os.path.normpath(self.shotpath)

        path = os.path.normpath(os.path.join(maya_file, '..', '..', '..'))
        matte_dir = os.path.join(path, 'alembic', 'character')

        # Check for char dir and get all char
        if os.path.exists(matte_dir):
            show_char = os.listdir(matte_dir)
            for c in show_char:
                # get all variables needed to populate comp flags
                c_matte_dir = os.path.join(matte_dir, c, 'mattes')
                if os.path.exists(c_matte_dir):
                    file_dump = os.listdir(c_matte_dir)
                    mattes = []
                    for f in file_dump:
                        if f.endswith('.png'):
                            mattes.append(f)

                    first_file = os.path.join(c_matte_dir, mattes[0])
                    # create comp for shot for each char
                    rnd_comp = self.set_comp(matte_dir, c, first_file, 1, len(mattes))

                    # if comp is created successfully, render it, else print notification of missing base comp.
                    if rnd_comp:
                        rnd_comp = rnd_comp.replace('\\', '/')
                        cmd = ["C:/rendernodedir/RenderNode.exe",
                                 str(rnd_comp),
                                 '-verbose',
                                 '-quit',
                                 '-render',
                                 '-start',
                                 '1',
                                 '-end',
                                 str(len(mattes))]

                        for output in self.run_popen(cmd):
                            print output,
                    else:
                        print('****** No comp for ' + c + ' found. ******')


if __name__ == "__main__":
    Process().run()
