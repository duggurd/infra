from pathlib import Path
from dbt.cli.main import dbtRunner
from dbt.contracts.graph.manifest import Manifest
from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument("projects_dir")
parser.add_argument("output_dir")
parser.add_argument("--profiles-dir", "-p", required=False)

def parse_project(projects_dir: Path, profiles_dir=None) -> Manifest:
    abs_path = projects_dir.absolute()

    project_name = abs_path.parts[-1]

    runner = dbtRunner()

    profiles_dir = profiles_dir if profiles_dir is not None else Path(__file__).parent.parent / "profiles"

    res = runner.invoke(["parse", "--project-dir", abs_path.__str__(), "--profiles-dir", profiles_dir.__str__()])

    if res.success and isinstance(res.result, Manifest):
        return res.result
    else:
        raise Exception(f"failed to parse project: {project_name}")
    

def save_msgpack_manifest(manifest: Manifest, output_dir: Path):
    project_name = manifest.metadata.project_name

    output_dir.mkdir(parents=True)

    with open(f"{output_dir}/{project_name}.msgpack" , "wb") as f:
        f.write(manifest.to_msgpack())

def parse_and_save_dbt_projects(projects_dir: Path, output_dir: Path, profiles_dir: Path|None=None):
    for project in projects_dir.iterdir():
        if project.is_dir():
            parsed_manifest = parse_project(project, profiles_dir)
            save_msgpack_manifest(parsed_manifest, output_dir)


def main():
    args = parser.parse_args()
    
    projects_dir =  Path(args.projects_dir)
    output_dir = Path(args.output_dir)
    profiles_dir = Path(args.profiles_dir) if args.profiles_dir else None

    parse_and_save_dbt_projects(projects_dir, output_dir, profiles_dir)


if __name__ == "__main__":
    main()