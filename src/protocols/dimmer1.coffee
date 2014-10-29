module.exports = (helper) ->
  # mapping for decoding
  pulsesToBinaryMapping = {
    '03': ''    #header
    '0200': '1' #binary 1
    '0002': '0' #binary 0
    '0000': 'N' #state = don't change
    '14': ''    #footer
  }
  # same for send
  binaryToPulse = {
    '1': '0200'
    '0': '0002'
    'N': '0000'
  }
  return protocolInfo = {
    name: 'dimmer1'
    type: 'dimmer'
    values:
      id:
        type: "binary"
      all:
        type: "boolean"
      state:
        type: "boolean"
      unit:
        type: "number"
      dimlevel:
        type: "number"
    brands: ["CoCo Technologies", "D-IO (Chacon)", "Intertechno", "KlikAanKlikUit", "Nexa"]
    pulseLengths: [255, 750, 1390, 2900, 11350]
    pulseCount: 148
    decodePulses: (pulses) ->
      # pulses is something like: '03000200020200000200020200000200020002020002000200020002000002
      #  02000200020000020002000200020002020002000002000200000002000200020002020002000200020014'
      # we first map the sequences to binary
      binary = helper.map(pulses, pulsesToBinaryMapping)
      # binary is now something like: '001000111101001000100110100100000001'
      # now we extract the data from that string
      #   00100100011111011100000110     0       N   0000    1111
      # | 00100011110100100010011010 |   0 |     1 | 0000 |  0001 |
      # | ID                         | All | State | unit | level |
      result = {
        id: helper.binaryToNumber(binary, 0, 25)
        all: helper.binaryToBoolean(binary, 26)
        unit: helper.binaryToNumber(binary, 28, 31)
        dimlevel: helper.binaryToNumber(binary, 32, 35)
      }
      if binary[27] isnt "N" 
        result.state = helper.binaryToBoolean(binary, 27)
      return result;

    encodeMessage: (message) ->
      id = helper.map(helper.numberToBinary(message.id, 26), binaryToPulse)
      all = (if message.all then binaryToPulse['1'] else binaryToPulse['0'])
      if message.state?
        state = (if message.state then binaryToPulse['1'] else binaryToPulse['0'])
      else
        state = binaryToPulse['N']
      unit = helper.map(helper.numberToBinary(message.unit, 4), binaryToPulse)
      dimlevel = helper.map(helper.numberToBinary(message.level, 4), binaryToPulse)
      return "03#{id}#{all}#{state}#{unit}#{dimlevel}14"
  }