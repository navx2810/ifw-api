mongoose = require 'mongoose'
mongoose.connect 'mongodb://localhost/ifw'
{Schema} = mongoose
{Types} = Schema


AccountSchema = new Schema
   email:
      type: Types.String
      required: true
      unique: true
   pass:
      type: Types.String
      required: true
   data: Types.Mixed

module.exports = Account = mongoose.model 'Account', AccountSchema
