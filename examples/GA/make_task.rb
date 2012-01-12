#!/usr/bin/env ruby

require 'optparse'

class Array
  def choice_by()
    weight = self.map{|x| [yield(x), 0.0].max}
    wiPair = []
    sum = 0.0
    self.length.times{|i|
      wiPair[i] = [weight[i],i]
      sum += weight[i]
    }
    
    coin = rand * sum
    self.length.times{|i|
      coin -= weight[i]
      return self[i] if coin <= 0
    }
    return self[wiPair.max[1]]
  end
end


Home = `echo $HOME`.strip
$workDir = '/work0/t2g-ppc-all/nushio/GA-DE'

opt = OptionParser.new
$newTasks = 0
opt.on('-n VAL') {|val| $newTasks = val.to_i}

$statFn = nil
opt.on('-s StatFileName') {|val| $statFn = val}

$statDir = nil
opt.on('--stat StatDirName') {|val|
  $statDir = val
  `mkdir -p #{$statDir}`
}

$injectDNA = nil
opt.on('-i INJECT_FN') {|fn|
  $injectDNA = []
  open(fn.to_s, 'r') {|fp|
    while line = fp.gets
      $injectDNA << line.strip
    end
  }
}

opt.on('-w WorkDir') {|dirn|
  $workDir = dirn
}

$mutateProb = 0.33333333333333
$crossProb  = 0.33333333333333
opt.on('--333') {
}
opt.on('--no3') {
  $mutateProb = 0.33333333
  $crossProb  = 0.66666667
}
opt.on('--on3') {
  $mutateProb = 0.33333333
  $crossProb  = 0.0
}


$islandMap = nil
opt.on('--island') {
  $islandMap = 
  [[0],
   [1],
   [2],
   [3],
   [0,1,4],
   [1,2,5],
   [2,3,6],
   [3,0,7],
   [0,4,7,8],
   [1,5,4,9],
   [2,6,5,10],
   [3,7,6,11],
   [0,1,2,3,4,5,6,7,8,9,10,11,12]
  ]
}


opt.parse!(ARGV)

STDERR.puts "**** #{$mutateProb}, #{$crossProb}"

`mkdir -p #{$workDir}`




$newTasks = $injectDNA.length  if $injectDNA 

$genomeBank  = {}
$genomeArray = []

class Species
  def mean()
    return @m_mean if @m_mean
    return @m_mean = 0 if @scores.length <= 0
    sum = 0.0
    @scores.each{|x| sum+=x}
    return @m_mean = sum / @scores.length
  end
  def devi()
    return @m_devi if @m_devi
    return @m_devi = 0 if @scores.length <= 1
    vari = 0.0
    @scores.each{|x|
      vari += (x - mean()) ** 2
    }
    return @m_devi = Math::sqrt(vari / (@scores.length - 1))
  end
  def trait()
    return "#{@id} #{mean()} #{devi()} #{contributionDistance()}"
  end

  def merge(other)
    @m_mean = nil;  @m_devi = nil
    @scores += other.scores
  end
  def stat()
    return sprintf("id:%08d\tn=%d\tscore = %f +/- %f",@id, @scores.length, mean(), devi())
  end
  attr_accessor :id, :dna, :scores, :m_mean, :m_devi, :parents, :parentFormat

  attr_accessor :contributionDistanceMemo
  def contributionDistance()
    return @contributionDistanceMemo if @contributionDistanceMemo
    ret = nil
    if @parents.length <= 0
      ret = 1
    else
      ret = @parents.map{|pid| $genomeArray[pid].contributionDistance() }.min + 1
    end
    return @contributionDistanceMemo = ret
  end
end

class FsCache
  def initialize()
    @record = []
  end

  def loadSpecies(id, dir)
    begin
      return @record[id] if id < @record.length - 50
      
      ret = Species.new
      ret.id = id
      ret.dna = open(dir + '/your.dna','r'){|fp| fp.read.strip }
      scores = []
      3.times{|gpuid|
        tmp = []
        open(dir + "/stdout#{gpuid}", 'r') {|fp|
          while line = fp.gets
            tmp << line.split(/\s+/)[1].to_f
          end
        }
        scores << tmp
      }
      n = scores.map{|xs|xs.length}.min
      
      ret.scores = []
      n.times{|i| 
        avg = (scores[0][i] + scores[1][i] + scores[2][i])/3
        ret.scores << avg
      }

      ret.parentFormat = ''
      ret.parents = []

      familyStr = open(dir + '/family-tree.txt', 'r') {|fp| fp.read.split(/\n/) }
      ret.parentFormat = familyStr[0]
      familyStr[1..-1].each{|dna|
        if $genomeBank.key?(dna)
          ret.parents << $genomeBank[dna].id
        end
      }
      
      return @record[id] = ret
    rescue
      return nil
    end
  end

  attr_accessor :record
end

def rand_dna()
  ret = 'GAATCT'
  0.times{
    ret += ['A','T','C','G'].sort_by{|x| rand()}[0]
  }
  return ret;
end

def indexToDir(i0)
  i = i0.to_i
  top = i / 1000
  bot = i % 1000
  return  $workDir + "/" + sprintf("%04d/%04d", top, bot)
end





ctr = 1
freeIndex = 0
ctr2 = 1

CacheFn = "#{$workDir}/fs.cache"
$fsCache = FsCache.new
if File.exist?(CacheFn)
  begin
    open(CacheFn, 'r'){|fp|
      $fsCache = Marshal.load(fp)
    }
  rescue
    $fsCache = FsCache.new
  end
end


loop {
  dir = indexToDir(ctr)
  unless File.exist?(dir)
    freeIndex = ctr
    break
  end
  spec = $fsCache.loadSpecies(ctr, dir)
  if (ctr > ctr2 || ctr%1000 == 0) 
    STDERR.puts "scanning: #{ctr}"
    ctr2=2*ctr
  end
  if spec && spec.scores.length > 0
    if $genomeBank[spec.dna]
      $genomeBank[spec.dna].merge(spec)
    else
      $genomeBank[spec.dna] = spec.clone
    end
  end
  ctr+=1
}


open(CacheFn, 'w'){|fp|
  Marshal.dump($fsCache, fp)
}


$genomeBank.each{|k,v|
  $genomeArray[v.id] = v
}

STDERR.puts "sorting..."
$genomeRanking = $genomeBank.values.sort_by{|spec| [spec.mean, -spec.id]}.reverse

STDERR.puts "sorted"
# $genomeRanking.each{|spec| puts spec.stat}

$topMean = $genomeRanking[0].mean if $genomeRanking[0]
$topDevi = 0
$genomeRanking.each{|spec| 
  if spec.devi > 0
    $topDevi = spec.devi
    break
  end
}

if $statFn
  open($statFn, 'w') {|fp|
    $genomeRanking.each{|spec|
      fp.puts "#{spec.id} #{spec.scores.length} #{spec.mean} #{spec.devi}"
    }
  }
end

def setContributor(id)
  return if $genomeArray[id].contributionDistanceMemo
  $genomeArray[id].contributionDistanceMemo = 0
  $genomeArray[id].parents.each{|pid|
    setContributor(pid)
  }
end

if $statDir
  # precalculate contributionDistance
  setContributor($genomeRanking[0].id)

  # print data
  open($statDir + '/stat.txt','w') {|fp|
    $genomeArray.each{|spec|
      next unless spec
      fp.puts "#{spec.trait}"
    }
  }

  # print child-parent pair
  open($statDir + '/tree.txt','w') {|fp|
    $genomeArray.each{|spec|
      next unless spec
      spec.parents.each{|pid|
        paren = $genomeArray[pid]
        fp.puts "#{spec.trait} #{paren.trait}"
      }
    }
  }

  # print how each children are born
  open($statDir + '/mutate.txt','w') {|fp1|
    open($statDir + '/cross.txt','w') {|fp2|
      open($statDir + '/triang.txt','w') {|fp3|   
        $genomeArray.each{|spec|
          next unless spec
          pids = spec.parents
          ps = pids.map{|id| $genomeArray[id]}
          case ps.length
          when 1
            fp1.puts "#{spec.trait} #{ps[0].trait}"
          when 2
            fp2.puts "#{spec.trait} #{ps[0].trait} #{ps[1].trait}"
          when 3
            fp3.puts "#{spec.trait} #{ps[0].trait} #{ps[1].trait} #{ps[2].trait}"
          end
        }
      }
    }
  }
  
  # output contributionDistance statistics
  open($statDir + '/contributionDistance.txt','w') {|fp|
    histogram = {}
    birthHistogram = {}
    $genomeArray.each{|spec|
      next unless spec
      d  = spec.contributionDistance()
      ps = spec.parents.length
      histogram[d] ||= 0
      histogram[d] += 1
      birthHistogram[d] ||= [0,0,0,0]
      birthHistogram[d][ps]+=1
    }
    histogram.to_a.sort.each{|k,v|
      fp.puts "#{k}\t#{v}\t" + birthHistogram[k].join("\t")
    }
  }
end


def randTemp()
  return 0 if $injectDNA
  
  lo = Math::log($topDevi) 
  #hi = Math::log($topMean) + Math::log($genomeBank.length.to_f)   
  hi = Math::log($topMean)

  return Math::exp(lo + rand() * (hi-lo))
end

def randSpec(temp, factor)
  $genomeBank.values.choice_by{|spec|
    diff = $topMean - spec.mean
    modTemp = temp+$topDevi+spec.devi

    envy = 1
    # envy = [1, 10 * (diff +$topDevi+spec.devi) / modTemp].min

    rand * Math::exp((-diff)/modTemp) * envy * factor[spec] + 1e-300*rand
  }
end


STDERR.puts "free index is #{freeIndex}"


newGenomeBank = {}

ConstFactor = lambda{|x| 1.0}

$newTasks.times {|i0|
  myIndex = i0 + freeIndex
  
  selector = [ConstFactor] * 3
  
  if $islandMap
    n = $islandMap.length
    remainder = myIndex % n
    cands = $islandMap[remainder]
    candIds = (cands.sort_by{rand}*3)[0..2]

    STDERR.puts "id #{myIndex} shall choose thy parent from #{candIds.join(',')}"
    
    selector = candIds.map{|x| lambda{|spec| if spec.id % n == x then 1.0 else 0.0 end } }
  end


  pwd = indexToDir(myIndex)
  `rm -fr #{pwd}`
  `mkdir -p #{pwd}`
  
  open(pwd + '/submit.sh','w') {|fp|
    fp.puts <<SCRIPT
t2sub -N #{rand_dna()} -q G -W group_list=t2g-ppc-all -l select=1:gpus=3:mem=21gb -l walltime=0:10:00 #{pwd}/exec.sh
SCRIPT
  }
  
  
  open(pwd + '/exec.sh','w') {|fp|
    fp.puts <<SCRIPT
cd #{pwd}
make kh-cuda.out > stdout 2> stderr
./kh-cuda.out 0 > stdout0 2> stderr0 &
./kh-cuda.out 1 > stdout1 2> stderr1 &
./kh-cuda.out 2 > stdout2 2> stderr2 
sleep 10
rm ./HydroMain
rm *.o
rm ./kh-cuda.out
SCRIPT
  }
  


  `chmod 755 #{pwd}/submit.sh`
  `chmod 755 #{pwd}/exec.sh`
  
  `cp Makefile #{pwd}/`
  `cp Hydro.hs #{pwd}/`
  `cp HydroMain.hs #{pwd}/`
  `cp main-kh.cu #{pwd}/`
  `cp get_time.h #{pwd}/`
  `ln -s #{Home}/.nvcc/include/thrust #{pwd}/thrust`
  `mkdir -p #{pwd}/output`


  temp = tempOrig = randTemp()
  STDERR.print "             #{sprintf('%0.3f',temp)} "[-16..-1]
  modifiedTemp = ''
  
  coin = rand()

  cmd = if $injectDNA
          :inject
        elsif coin < $mutateProb
          :mutate
        elsif coin < $mutateProb + $crossProb
          :cross
        else
          :triang
        end

  if cmd == :inject
    dna = $injectDNA[i0]
    STDERR.puts "injection #{dna}"
    open("#{pwd}/your.dna", 'w') {|fp|
      fp.puts <<DNA
#{dna}
DNA
    }
    
    open("#{pwd}/family-tree.txt",'w'){|fp|
      fp.puts <<TREE
OP
TREE
    }
    
    
  end
  while cmd == :cross
    a = randSpec(temp,selector[0])
    b = randSpec(temp,selector[1])
    100.times{
      break if a.id != b.id
      temp *= 1.2
      b = randSpec(temp,selector[1])
      modifiedTemp = "(#{temp})"
    }

    dna = `./mutate.hs #{a.dna} #{b.dna}`.strip
    STDERR.puts "cross  #{a.id} #{b.id}  #{modifiedTemp}"
    if $genomeBank[dna] || newGenomeBank[dna]
      STDERR.puts 'duplicate'
      cmd = :mutate
      break
    end
    STDERR.puts 'not duplicate'
    open("#{pwd}/your.dna",'w'){|fp| fp.puts dna}
    open("#{pwd}/family-tree.txt",'w'){|fp|
      fp.puts <<TREE
2P
#{a.dna}
#{b.dna}
TREE
    }
    break
  end
  while cmd == :triang
    xs = [randSpec(temp,selector[0]), randSpec(temp,selector[1]), randSpec(temp,selector[2])].sort_by{|spec| spec.mean}
    a = xs[0]
    b = xs[1]
    c = xs[2]
    100.times{
      break if a.id != b.id && a.id != c.id && b.id != c.id
      temp *= 1.2
      xs = [randSpec(temp,selector[0]), randSpec(temp,selector[1]), randSpec(temp,selector[2])].sort_by{|spec| spec.mean}
      a = xs[0]
      b = xs[1]
      c = xs[2]
      modifiedTemp = "(#{temp})"
    }
    
    dna = `./mutate.hs #{a.dna} #{b.dna} #{c.dna}`.strip
    STDERR.puts "triang #{a.id} #{b.id} #{c.id} #{modifiedTemp}"
    if $genomeBank[dna] || newGenomeBank[dna]
      STDERR.puts 'duplicate'
      cmd = :mutate
      break
    end
    STDERR.puts 'not duplicate'
    open("#{pwd}/your.dna",'w'){|fp| fp.puts dna}

    open("#{pwd}/family-tree.txt",'w'){|fp|
      fp.puts <<TREE
3P
#{a.dna}
#{b.dna}
#{c.dna}
TREE
    }
    break
  end
  while cmd == :mutate
    temp = tempOrig
    a = randSpec(temp,selector[0])

    STDERR.puts "mutate #{a.id}"
    dna = `./mutate.hs #{a.dna}`.strip
    if $genomeBank[dna] || newGenomeBank[dna]
      STDERR.puts 'duplicate'
      next
    end

    STDERR.puts 'not duplicate'
    open("#{pwd}/your.dna",'w'){|fp| fp.puts dna}
    open("#{pwd}/family-tree.txt",'w'){|fp|
      fp.puts <<TREE
1P
#{a.dna}
TREE
    }
    break
  end

  STDERR.puts "submitting..."
  exit() unless system("bash #{pwd}/submit.sh")
  newGenomeBank[dna] = true
}
