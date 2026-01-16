# Hyperproof

We use [Hyperproof] for our compliance and audit management. This includes
tracking proof of our compliance. This component gathers evidence of our
compliance and security controls across different systems, and publishes it to
Hyperproof.

## Proofs

Proofs are collected from different sources, and published to Hyperproof under
an appropriate label. These labels can be applied to different controls in order
to link proofs for auditing.

The following proofs are currently collected:

| Label               | Source  | Proof               |
| ------------------- | ------- | ------------------- |
| Database Encryption | Aptible | Database encryption |
| Database Encryption | AWS     | Database encryption |
| Disk Encryption     | AWS     | EFS encryption      |
| Disk Encryption     | AWS     | Volume encryption   |

## Adding new source and proofs

Each proof is presented by a Ruby class that adheres to an interface. They are
organization into submodules for each source.
`CfaSecurityControls::Hyperproof::Proofs` is the top level namespace, with an
abstract[abstract-classes] base class named `Proofs`.

These classes are located in
[`hyperproof/lib/cfa_security_controls/hyperproof/proofs/*`][proofs-dir].

> [!TIP]
> When implementing a new source or proof, use existing sources and proofs as
> a guideline.

### Adding a new source

If an existing source doesn't exist for your proof, you can add a new one by
defining a namespace, base class, and any additional classes (e.g. an HTTP
client) to suppor the new source.

1. Create a new module under the `proofs` directory, named for your source
1. Create a base class under `proofs/#{source_name}` and define any shared
   functionality for proofs from this source
1. If possible, implement a generic `collect` method to handle collecting proofs
   of any kind from the source
1. If needed, create additional resources required for interacting with the
   source under `CfaSecurityControls::Hyperproof::Clients`
1. Follow the [existing source][existing] steps below to add your individual
   proofs

### Adding to existing source

If a source exists for your proof, you're already most of the way there! Follow
the steps below to create an individual proof for a source.

> [!TIP]
> Each source has its own base class that can be used to encapsulate common
> logic for the source. Refer to the base class for any additional methods you
> may need to define for that source.

1. Create a new class under the approptaite directory and namespace
1. Extend the base class for the source
1. Define the `name` and `label` methods to describe the proof
1. If the source base class doesn't implement `collect`, do so in your class
1. Define any additional logic required to fetch and process the proof

## Syncing

This component is designed to be run via GitHub Actions, though it can be run
locally with the appopraite credentials provided.

### GitHub Actions

> [!TIP]
> You can choose a different branch to run the workflow on when triggering
> manually. This can be useful to test your changes before they are merged.

The [hyperproof workflow][workflow] runs the sync on the first of every month.
The workflow includes a `workflow_dispatch` and can be triggered manually from
the [GitHub Actions][actions] tab of the repository.

Secrets and variables for GitHub are managed in [Doppler] and synced to GitHub
environmments.

### Locally

To run locally, you will need to configure credentials for the following
services:

- **Aptible**: Create a [client token for SSO][aptible-token]
- **AWS**: Set `AWS_PROFILE` to the appropriate profile and run `aws sso login`
- **Hyperproof**: Create [personal API credentials][hyperproof-creds] with the
  following scopes: `label.read`, `label.update`, `proof.read`, `proof.update`;
  set the credentials in `HYPERPROOF_CLIENT_ID` and `HYPERPROOF_CLIENT_SECRET`
  in your personal Doppler branch for this project

With the proper credentials set, follow the steps below to run locally:

1. If you haven't setup doppler for the project, run `doppler setup`
1. Import secrets from Doppler:

    ```bash
    source <(doppler secrets download --no-file --format env)
    ```

1. Change to the `hyperproof` directory: `cd hyperproof`
1. Install dependencies: `bundle install`
2. Run the CLI tool to verify installation:
   
    ```bash
    bundle exec ./bin/hyperproof help
    ```

1. Run the sync:

    ```bash
    bundle exec ./bin/hyperproof sync
    ```

[actions]: https://github.com/codeforamerica/cfa-security-controls/actions/workflows/hyperproof.yaml
[aptible-token]: https://www.aptible.com/docs/core-concepts/security-compliance/authentication/sso#cli-token-for-sso
[doppler]: https://dashboard.doppler.com/workplace/08430c37e2a2889dc220/projects/cfa-security-controls
[hyperproof]: https://hyperproof.io/
[hyperproof-creds]: https://developer.hyperproof.app/guides/oauth-client-credentials#2OH2H
[proofs-dir]: https://github.com/codeforamerica/cfa-security-controls/tree/main/hyperproof/lib/cfa_security_controls/hyperproof/proofs
[workflow]: https://github.com/codeforamerica/cfa-security-controls/blob/main/.github/workflows/hyperproof.yaml
