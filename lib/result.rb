#!/usr/bin/env ruby

require 'set'

DEFAULT_COMPILER = 'gcc-4.9'

RESULT_MNT	= '/result'
RESULT_PATHS	= '/lkp/paths'
RESULT_ROOT_DEPTH = 8

def tbox_group(hostname)
	hostname.sub /-[0-9]+$/, ''
end

def is_tbox_group(hostname)
	Dir[LKP_SRC + '/hosts/' + hostname][0]
end

class ResultPath < Hash
	MAXIS_KEYS = ['testbox', 'testcase', 'path_params', 'rootfs', 'kconfig', 'commit'].freeze
	AXIS_KEYS = (MAXIS_KEYS + ['run']).freeze

	PATH_SCHEME = {
		'legacy'	=> %w[ testcase path_params rootfs kconfig commit run ],
		'default'	=> %w[ path_params tbox_group rootfs kconfig compiler commit run ],
		'health-stats'	=> %w[ path_params run ],
		'hwinfo'	=> %w[ tbox_group run ],
	}

	def path_scheme
		PATH_SCHEME[self['testcase']] || PATH_SCHEME['default']
	end

	def parse_result_root(rt)
		dirs = rt.sub(RESULT_MNT, '').split('/')
		dirs.shift if dirs[0] == ''

		self['testcase'] = dirs.shift
		ps = path_scheme()

		# for backwards compatibilty
		if is_tbox_group(self['testcase'])
			self['tbox_group'] = self['testcase']
			ps = PATH_SCHEME['legacy']
		end

		ps.each do |key|
			self[key] = dirs.shift
		end
	end

	def assemble_result_root(skip_keys = nil)
		dirs = [
			RESULT_MNT,
			self['testcase']
		]

		path_scheme.each do |key|
			next if skip_keys and skip_keys.include? key
			dirs << self[key]
		end

		dirs.join '/'
	end

	def _result_root
		assemble_result_root ['run'].to_set
	end

	def result_root
		assemble_result_root
	end

	def test_desc(dim, dim_not_a_param)
		self.delete(dim) if dim_not_a_param
		self.delete('rootfs') if dim != 'rootfs'
		self.delete('kconfig') if dim != 'kconfig'
		[
			self['testcase'],
			self['path_params'],
			self['tbox_group'],
			self['rootfs'],
			self['kconfig'],
			self['commit']
		].compact.join '/'
	end

	def params_file
		[
			RESULT_MNT,
			self['testcase'],
			'params.yaml'
		].join '/'
	end
end

class << ResultPath
	def parse(rt)
		rp = new
		rp.parse_result_root(rt)
		rp
	end

	def new_from_axes(axes)
		rp = new
		rp.update(axes)
		rp
	end
end
