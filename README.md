<a id="readme-top"></a>

<h1 align="center">Janus Core</h1>

<div align="center">
  <a href="https://github.com/janus-bastion">
    <img src="https://github.com/janus-bastion/janus-frontend/blob/main/public/janus-logo.png" alt="Janus Bastion Logo" width="160" height="160" />
  </a>

  <p><em>Core runtime of the Janus bastion: handles user authentication, protocol bridging (SSH, RDP), and user-machine access logic</em></p>

  <p>
    <a href="https://github.com/janus-bastion/janus-core/actions">
      <img src="https://github.com/janus-bastion/janus-core/actions/workflows/ci.yml/badge.svg" alt="CI Status" />
    </a>
  </p>

  <table align="center">
    <tr>
      <th>Author</th>
      <th>Author</th>
      <th>Author</th>
      <th>Author</th>
    </tr>
    <tr>
      <td align="center">
        <a href="https://github.com/nathanmartel21">
          <img src="https://github.com/nathanmartel21.png?size=115" width="115" alt="@nathanmartel21" /><br />
          <sub>@nathanmartel21</sub>
        </a><br /><br />
        <a href="https://github.com/sponsors/nathanmartel21">
          <img src="https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=white" alt="Sponsor nathanmartel21" />
        </a>
      </td>
      <td align="center">
        <a href="https://github.com/xeylou">
          <img src="https://github.com/xeylou.png?size=115" width="115" alt="@xeylou" /><br />
          <sub>@xeylou</sub>
        </a><br /><br />
        <a href="https://github.com/sponsors/xeylou">
          <img src="https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=white" alt="Sponsor xeylou" />
        </a>
      </td>
      <td align="center">
        <a href="https://github.com/Djegger">
          <img src="https://github.com/Djegger.png?size=115" width="115" alt="@Djegger" /><br />
          <sub>@Djegger</sub>
        </a><br /><br />
        <a href="https://github.com/sponsors/Djegger">
          <img src="https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=white" alt="Sponsor Djegger" />
        </a>
      </td>
      <td align="center">
        <a href="https://github.com/Warsgo">
          <img src="https://github.com/Warsgo.png?size=115" width="115" alt="@Warsgo" /><br />
          <sub>@Warsgo</sub>
        </a><br /><br />
        <a href="https://github.com/sponsors/Warsgo">
          <img src="https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=white" alt="Sponsor Warsgo" />
        </a>
      </td>
    </tr>
  </table>
</div

>---

## Contents

- [`./scripts/`](./scripts): user auth + protocol access logic - SSH, RDP (e.g. [`janus.sh`](./scripts/janus.sh), [`auth.sh`](./scripts/auth.sh))
- [`./Dockerfile`](./Dockerfile): container runtime with dialog, PHP, and database client tools
- [`./.github/workflows/ci.yml`](./.github/workflows/ci.yml): ShellCheck linting and Docker image build

---

## Features

- Terminal-based UI
- PHP + MariaDB user authentication
- Configurable access
- ShellCheck CI linting + Docker build
- Self-contained runtime image

### In progress / upcoming
- SSH access based on user permissions
- RDP certificate generation (Windows)
- Rebound / chained SSH connection mode
- Script argument parsing (non-interactive mode)
- Machine registration (SSH/RDP)

## Notes

*I hope I don't forget them...*

---

## License

This project is licensed under the GNU General Public License v3.0.  
See the [LICENSE](./LICENSE) file for details.
