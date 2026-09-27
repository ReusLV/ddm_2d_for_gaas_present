# Public release checklist

This working repository is ready to present locally, but its existing Git history should not be pushed directly to a new public GitHub repository.

## Before publishing

- Confirm that the thesis PDF may be distributed publicly and that it contains no personal information you do not want indexed.
- Confirm that the COMSOL `.mph` models and exported data may be redistributed.
- Choose a software license. Until a license is added, other people do not receive permission to reuse or redistribute the code.
- Update the citation section with the thesis author, title, institution, and year if you want the repository to be cited.
- Run `git status` and review every staged change before the public commit.
- Run MATLAB Code Analyzer and execute `plot_saved_results`; run the full solver when time permits.

## Publish a clean mirror

The current working tree is roughly 48 MB, but the inherited Git object database is about 4.06 GiB because older commits contain large generated artifacts. Preserve this repository as the private archive and create a new repository from the current working tree so the public clone does not inherit those objects.

One safe approach is:

1. Copy the working tree to a new directory without the `.git` directory.
2. Review the copied files, especially `docs/` and `comsol_reference/`.
3. Run `git init`, create a single initial commit, and connect the new GitHub remote.
4. Push the new repository only after confirming its size and contents.

Do not rewrite the history of the archival repository unless you have a separate verified backup.

## Suggested GitHub metadata

- **Description:** `From-scratch 2D GaAs drift–diffusion FEM solver in MATLAB, validated against COMSOL.`
- **Topics:** `matlab`, `finite-element-method`, `semiconductor`, `drift-diffusion`, `gaas`, `device-simulation`, `comsol`, `computational-physics`
- **Social preview:** use `figures/structure_dimensions.png` or a composite of the device structure and the Schottky I–V plot.
