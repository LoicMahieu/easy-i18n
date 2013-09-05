
module.exports = (sequelize, DataTypes) ->
  sequelize.define "I18n",
    language:
      type: DataTypes.STRING
      validate:
        notNull: true
        notEmpty: true

    key:
      type: DataTypes.STRING
      validate:
        notNull: true
        notEmpty: true

    value:
      type: DataTypes.STRING(1000)

    namespace:
      type: DataTypes.STRING
      validate:
        notNull: true
        notEmpty: true

    used:
      type: DataTypes.BIGINT
      defaultValue: 0