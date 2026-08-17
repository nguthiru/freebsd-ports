# Populate deps/ from pre-fetched Hex tarballs, offline.
#
# Usage: elixir unpack_deps.exs <mix.lock> <tarball-dir> <deps-dir>
#
# Each Hex tarball is an uncompressed .tar holding VERSION, CHECKSUM,
# metadata.config and contents.tar.gz. Mix decides whether a dependency is
# "fetched" by reading deps/<name>/.hex and comparing it against mix.lock, so
# that marker has to be written too -- it is an :erlang.term_to_binary of
# {{:hex, 2, 0}, %{...}} built entirely from the lock entry.

[lock_path, tar_dir, deps_dir] = System.argv()

{lock, _} = Code.eval_file(lock_path)

for {key, entry} <- lock do
  {:hex, dep, version, inner, managers, _deps, repo, outer} = entry

  # mix.lock is written with quoted-keyword syntax, so its keys are atoms.
  name = to_string(key)
  tarball = Path.join(tar_dir, "#{name}-#{version}.tar")

  if File.exists?(tarball) do
    dest = Path.join(deps_dir, name)
    File.rm_rf!(dest)
    File.mkdir_p!(dest)

    tmp = Path.join(System.tmp_dir!(), "hexunpack-#{name}-#{version}")
    File.rm_rf!(tmp)
    File.mkdir_p!(tmp)

    :ok = :erl_tar.extract(String.to_charlist(tarball), [{:cwd, String.to_charlist(tmp)}])

    :ok =
      :erl_tar.extract(
        String.to_charlist(Path.join(tmp, "contents.tar.gz")),
        [:compressed, {:cwd, String.to_charlist(dest)}]
      )

    File.cp!(Path.join(tmp, "metadata.config"), Path.join(dest, "hex_metadata.config"))

    File.write!(
      Path.join(dest, ".hex"),
      :erlang.term_to_binary(
        {{:hex, 2, 0},
         %{
           name: Atom.to_string(dep),
           version: version,
           repo: repo,
           managers: managers,
           inner_checksum: inner,
           outer_checksum: outer
         }}
      )
    )

    File.rm_rf!(tmp)
    IO.puts("unpacked #{name} #{version}")
  end
end
