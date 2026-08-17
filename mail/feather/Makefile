PORTNAME=	feather
DISTVERSIONPREFIX=	v
DISTVERSION=	1.0.102
CATEGORIES=	mail
MASTER_SITES=	https://repo.hex.pm/tarballs/:hex
DISTFILES=	${HEX_DEPS:C/$/.tar:hex/}
DIST_SUBDIR=	${PORTNAME}
EXTRACT_ONLY=	${DISTFILES:N*\:hex:C/\:.*//}

MAINTAINER=	nguthiruedwin@gmail.com
COMMENT=	Pluggable SMTP mail server (MSA/MTA) built on the BEAM
WWW=		https://github.com/yoonka/feather/

LICENSE=	BSD3CLAUSE
LICENSE_FILE=	${WRKSRC}/LICENSE

# The Mix release embeds ERTS and the bcrypt_elixir / iconv NIFs.
ONLY_FOR_ARCHS=	aarch64 amd64

BUILD_DEPENDS=	elixir:lang/elixir \
		rebar3:devel/rebar3

USES=		gmake iconv ssl

USE_GITHUB=	yes
GH_ACCOUNT=	yoonka
# Hex is needed to compile the dependencies but is not a port, and
# `mix local.hex` is a network call. Hex builds from its own source with
# neither a network nor a pre-existing Hex, via `mix archive.build`.
GH_TUPLE=	hexpm:hex:v${HEX_VER}:hexsrc

USE_RC_SUBR=	feather

SUB_FILES=	pkg-message
SUB_LIST=	PORTNAME=${PORTNAME} \
		FEATHER_DIR=${FEATHER_DIR} \
		FEATHER_LOGDIR=${FEATHER_LOGDIR} \
		FEATHER_RUNDIR=${FEATHER_RUNDIR} \
		FEATHER_USER=${USERS} \
		FEATHER_GROUP=${GROUPS}

# The dedicated account owns the config, log and run directories. Note that
# the service still starts as root by default: Feather binds the privileged
# SMTP ports (25, 465, 587) and the release does not drop privileges on its
# own, so feather_user is only useful on hosts that have arranged
# unprivileged access to those ports.
USERS=		feather
GROUPS=		feather

PLIST_SUB=	FEATHER_LOGDIR=${FEATHER_LOGDIR} \
		FEATHER_RUNDIR=${FEATHER_RUNDIR} \
		FEATHER_USER=${USERS} \
		FEATHER_GROUP=${GROUPS}

OPTIONS_DEFINE=	EXAMPLES
OPTIONS_DEFAULT=	EXAMPLES
OPTIONS_SUB=	yes

# Mix release layout: the whole self-contained release lands in
# ${PREFIX}/lib/feather, with bin/feather symlinked into ${PREFIX}/bin.
# The release launcher resolves RELEASE_ROOT through the symlink.
FEATHER_DIR=	${PREFIX}/lib/${PORTNAME}
FEATHER_LOGDIR?=	/var/log/${PORTNAME}
FEATHER_RUNDIR?=	/var/run/${PORTNAME}

HEX_VER=	2.5.1

# Every Hex dependency is fetched as its own checksummed distfile and
# unpacked straight into ${WRKSRC}/deps, the same way net-im/ejabberd handles
# its rebar dependencies with GH_TUPLE. Nothing touches the network after the
# fetch phase, and `mix deps.get` is never run. Regenerate this list from
# mix.lock after a version bump; the SHA256 of each tarball is already
# recorded there as the dependency's outer checksum.
HEX_DEPS=	bcrypt_elixir-3.3.2 \
		briefly-0.5.1 \
		comeonin-5.5.1 \
		elixir_make-0.9.0 \
		file_system-1.1.1 \
		finch-0.21.0 \
		gen_smtp-1.3.0 \
		hpax-1.0.3 \
		iconv-1.0.14 \
		jason-1.4.4 \
		mime-2.0.7 \
		mint-1.7.1 \
		nimble_options-1.1.1 \
		nimble_pool-1.1.0 \
		ranch-2.2.0 \
		req-0.5.17 \
		telemetry-1.4.1

# USES=elixir is deliberately not used here. Mk/Uses/elixir.mk installs an
# application into ${PREFIX}/lib/elixir/lib/${PORTNAME} and rewrites mix.exs
# so that every dependency resolves to another port under ELIXIR_LIB_ROOT.
# No Elixir library ports exist in the tree, so this port builds a
# self-contained Mix release instead and wants no run-time dependency on
# lang/elixir.
_MIX_HOME=	${WRKDIR}/.mix
_HEX_HOME=	${WRKDIR}/.hex

# elixir_make (bcrypt_elixir) and the iconv rebar3 port driver both expect
# GNU make; MIX_REBAR3 keeps Mix from trying to download its own rebar3.
_MIX_ENV=	HOME=${WRKDIR} \
		MIX_HOME=${_MIX_HOME} \
		HEX_HOME=${_HEX_HOME} \
		HEX_OFFLINE=1 \
		MIX_ENV=prod \
		MIX_REBAR3=${LOCALBASE}/bin/rebar3 \
		MAKE=${LOCALBASE}/bin/gmake \
		LANG=en_US.UTF-8 \
		LC_ALL=en_US.UTF-8

MIX_CMD=	${LOCALBASE}/bin/mix

post-extract:
	@${MKDIR} ${_MIX_HOME} ${_HEX_HOME} ${WRKSRC}/deps
	@${ECHO_MSG} "===>  Building the Hex archive from source"
	cd ${WRKSRC_hexsrc} && ${SETENV} ${_MIX_ENV} \
		${MIX_CMD} archive.build -o ${WRKDIR}/hex.ez
	cd ${WRKSRC_hexsrc} && ${SETENV} ${_MIX_ENV} \
		${MIX_CMD} archive.install --force ${WRKDIR}/hex.ez
	@${ECHO_MSG} "===>  Unpacking Hex dependencies into deps/"
	cd ${WRKSRC} && ${SETENV} ${_MIX_ENV} ${LOCALBASE}/bin/elixir \
		${FILESDIR}/unpack_deps.exs mix.lock \
		${DISTDIR}/${DIST_SUBDIR} ${WRKSRC}/deps

do-build:
	@${ECHO_MSG} "===>  Building Mix release"
	cd ${WRKSRC} && ${SETENV} ${_MIX_ENV} ${MIX_CMD} release --overwrite

do-install:
	@${MKDIR} ${STAGEDIR}${FEATHER_DIR}
	cd ${WRKSRC}/_build/prod/rel/${PORTNAME} && \
		${COPYTREE_BIN} . ${STAGEDIR}${FEATHER_DIR}
	${RLN} ${STAGEDIR}${FEATHER_DIR}/bin/${PORTNAME} \
		${STAGEDIR}${PREFIX}/bin/${PORTNAME}

post-install:
	@${MKDIR} ${STAGEDIR}${ETCDIR}
.for f in server.exs pipeline.exs
	${INSTALL_DATA} ${WRKSRC}/config/examples/${f} \
		${STAGEDIR}${ETCDIR}/${f}.sample
.endfor
	@${MKDIR} ${STAGEDIR}${FEATHER_LOGDIR} ${STAGEDIR}${FEATHER_RUNDIR}
	@${MKDIR} ${STAGEDIR}${FEATHER_DIR}/tmp
# The embedded ERTS ships unstripped binaries, and erts-*/bin mixes ELF
# executables with shell scripts, so the file type has to be tested rather
# than stripping by name. COPYTREE_BIN leaves everything at BINMODE, which
# has no write bit, so strip(1) cannot rewrite the file in an unprivileged
# build until the bit is restored afterwards. STRIP_CMD is "true" under
# WITH_DEBUG.
	@${FIND} ${STAGEDIR}${FEATHER_DIR} -type f -exec ${SH} -c \
		'for f; do case "$$(${FILE} -b "$$f")" in \
			ELF*) ${CHMOD} u+w "$$f"; ${STRIP_CMD} "$$f"; \
			      ${CHMOD} ${BINMODE} "$$f" ;; \
		esac; done' _ {} +
# The release is roughly 1100 files, and because it embeds ERTS the exact set
# tracks whichever lang/erlang built it. Enumerating it here keeps the port
# from having to be touched on every Erlang bump. generate-plist runs before
# post-install, so appending works.
	@cd ${STAGEDIR}${PREFIX} && \
		${FIND} lib/${PORTNAME} \( -type f -o -type l \) | ${SORT} >> ${TMPPLIST}
	@cd ${STAGEDIR}${PREFIX} && \
		${FIND} lib/${PORTNAME} -type d | ${SORT} -r | \
		${SED} -e 's,^,@dir ,' >> ${TMPPLIST}

post-install-EXAMPLES-on:
	@${MKDIR} ${STAGEDIR}${EXAMPLESDIR}
	cd ${WRKSRC}/config/examples && \
		${COPYTREE_SHARE} . ${STAGEDIR}${EXAMPLESDIR}

.include <bsd.port.mk>
